package GSC::PSE::FTPToGenBank;
use strict;
use warnings FATAL => qw(all);
use Net::FTP;
use String::TT qw(tt strip);

sub confirm {
    my $self = shift;
    return unless $self->SUPER::confirm;

    unless ( do { no warnings 'once'; $App::Mail::DISABLE_FOR_TESTING } or App::DBI->no_commit) {
        $self->do_ftp;
        $self->send_mail;
    }
    $self->get_genbank_assembly_submission->status('transferred');
    $self->delete_temp_data();

    return 1;
}

sub delete_temp_data {
    my $self = shift;
    my $execute_tbl2asn    = $self->get_prior_pse;
    my $initialize_tbl2asn = $execute_tbl2asn->get_prior_pse;
    my ($alloc_pse)        = $initialize_tbl2asn->get_disk_allocation_pse;
    $alloc_pse->delete_and_deallocate;
}

sub get_genbank_assembly_submission {
    shift->get_first_prior_pse_with_process_to(
        'configure assembly submission to genbank')
            ->get_genbank_assembly_submission
}

sub do_ftp {
    my $self = shift;
    local $@;

    my $ftp = Net::FTP->new('ftp-private.ncbi.nlm.nih.gov', Passive => 1);
    die "Unable to construct FTP object per $@" unless($ftp);
    $ftp->login('wugsc', 'hum+seqs') or die 'FTP login failed '.$ftp->message;
    $ftp->cwd('TEMP') or die 'FTP cwd failed '.$ftp->message;
    $ftp->binary or die 'FTP binary failed '.$ftp->message;

    my $file = $self->tar_file;
    $self->status_message("About to ftp $file");

    my $ftp_result  = $ftp->put($file->stringify);
    if ($ftp_result) {
        $self->status_message("ftp success, result: $ftp_result; message:".$ftp->message);
    } else {
        die "ftp failed: ".($ftp->message||'');
    }
}

sub send_mail {
    my $self = shift;
    my $email_ncbi = $self->genbank_assembly_submission->email_ncbi;

    my $mail_subject = $self->mail_subject||'';
    my $mail_message = $self->mail_message||'';

    unless (length($mail_subject)) {
        die "Mail subject was not correctly constructed!\n";
    }

    unless (length($mail_message)) {
        die "Mail message was not correctly constructed!\n";
    }

    unless ($email_ncbi) {
        $mail_subject = '[EMAIL NOT SENT TO NCBI]: ' . $mail_subject;
    }

    my $subject_and_message = "Subject: $mail_subject\nMessage:\n$mail_message\n\n";
    $self->status_message("About to send mail:\n$subject_and_message");

    my $mail_result;
    if ($email_ncbi) {
        $self->status_message("Sending email to NCBI");
        $mail_result = App::Mail->mail(
            'From'     => q|submissions@genome.wustl.edu|,
            'To'       => q|genomes@ncbi.nlm.nih.gov|,
            'Cc'       => q|submissions@genome.wustl.edu|,
            'Subject'  => $mail_subject,
            'Message'  => $mail_message,
        );
    }
    else {
        $self->status_message("NOT Sending email to NCBI");
        $mail_result = App::Mail->mail(
            'From'     => q|submissions@genome.wustl.edu|,
            'To'       => q|submissions@genome.wustl.edu|,
            'Subject'  => $mail_subject,
            'Message'  => $mail_message,
        );
    }

    $self->status_message("Mail result:\n$mail_result");

    return $mail_result;
}

sub mail_subject {
    my $self = shift;

    my %h = $self->genbank_assembly_submission->query_bioproject(
        'Organism_Name',
        'Project_Title'
    );

    unless ($h{'Project_Title'}) {
        die
          "[err] Did not find a 'Project_Title' for GenBank Assembly Submission - ",
          'gas_id: ',
          $self->genbank_assembly_submission->gas_id, ' (',
          'bioproject_id: ',
          $self->genbank_assembly_submission->bioproject_id, ' ',
          'creation_event_id: ',
          $self->genbank_assembly_submission->creation_event_id, ")\n";
    }

    unless ($h{'Organism_Name'}) {
        die
          "[err] Did not find a 'Organism_Name' for GenBank Assembly Submission - ",
          'gas_id: ',
          $self->genbank_assembly_submission->gas_id, ' (',
          'bioproject_id: ',
          $self->genbank_assembly_submission->bioproject_id, ' ',
          'creation_event_id: ',
          $self->genbank_assembly_submission->creation_event_id, ")\n";
    }

    my ($org_name, $prj_title) = @h{'Organism_Name', 'Project_Title'};
    my $bioproject_id = $self->genbank_assembly_submission->bioproject_id;

    my $subject = "New '$org_name' - '$prj_title' [BioProject: $bioproject_id] assembly submission";
    return $subject;
}

sub mail_message {
    my $self = shift;

    my %h = $self->genbank_assembly_submission->query_bioproject(
        'Organism_Name', 'Organism_Strain', 'Project_Title');
    die unless %h;

    my $bioproject_id = $self->genbank_assembly_submission->bioproject_id;
    my $biosample_id = $self->genbank_assembly_submission->biosample_id;
    my $release_date  = $self->genbank_assembly_submission->release_date;
    my $tar_file      = $self->tar_file->basename;

    my $msg = strip tt qq{
        The McDonnell Genome Institute has submitted a new assembly to GenBank.

            Organism Name: [% h_h.Organism_Name %]
            Strain: [% h_h.Organism_Strain %]

        This assembly is being submitted as part of the '[% h_h.Project_Title %]' project
        with BioProject ID: [% bioproject_id_s %] and BioSample [% biosample_id_s %] .
        
        Please find [% tar_file_s %] on ftp-private.ncbi.nlm.nih.gov

        Release Date: [% release_date_s %]
    };

    return $msg;
}

sub genbank_assembly_submission {
    my $self = shift;
    my $configure_pse = $self->get_first_prior_pse_with_process_to(
        "configure assembly submission to genbank");
    return $configure_pse->get_genbank_assembly_submission;
}

sub tar_file {
    my $self = shift;

    my $results_dir = $self->get_prior_pse->results_dir_path;
    my $tar_file_path = $results_dir->file(
        $self->genbank_assembly_submission->version .'.tar');

    unless (-e $tar_file_path) {
        $self->error_message("Expected to find $tar_file_path.  Not found.");
        die;
    }

    return $tar_file_path;
}

sub expunge_execution {
    my $self = shift;

    if (($self->pse_status eq 'confirm') and ($self->pse_result eq 'failed')) {
        return 1;
    }

    $self->error_message("This assembly has already been transmitted to GenBank -- refusing to expunge.");
    return;
}

1;
