package RefImp::Assembly::Command::Submit;

use strict;
use warnings FATAL => qw(all);

use MIME::Lite;
use String::TT qw(tt strip);
use RefImp::Resources::NcbiFtp;

class RefImp::Assembly::Command::Submit {
    is => 'Command::V2',
    has_input => {
        submission_yml => {
            is => 'Text',
            doc => 'YAML with submission info. Use "submission-yaml" command for a template.',
        },
    },
    has_optional_transient => {
        submission => { is => 'RefImp::Project::Submission', },
    },
};

sub execute {
    my $self = shift;
    $self->status_message('Submit assembly...');

    $self->_create_submission_record;
    $self->_create_submission_tar;
    $self->_ftp_to_ncbi;
    $self->_send_mail;

    $self->status_message('Submit assembly...OK');
    1;
}

sub _create_submission_record {
    my $self = shift;

    my $submission = RefImp::Assembly::Submission->create_from_yml($self->submission_yml);
    if ( my @errors = $submission->__errors__ ) {
        $self->fatal_message( join("\n", map { $_->__display_name__ } @errors) );
    }
    $self->status_message('Created submission record: %s', $submission->__display_name__);

    $self->status_message('Validating submission for submit...');
    $submission->validate_for_submit;
    $self->status_message('Validating submission for submit...OK');

    $self->submission($submission);
}

sub _create_submission_tar {
    my $self = shift;
}

sub _ftp_to_ncbi {
    my $self = shift;
    $self->status_message('FTP to NCBI...OK');
    return 1;

    my $ftp = RefImp::Resources::NcbiFtp->connect;
    $self->status_message('Entering remote directory TEMP');
    $ftp->cwd('TEMP') or $self->fatal_message('Failed to FTP->cwd! %', $ftp->message);
    $self->status_message('Setting FTP binary mode');
    $ftp->binary or $self->fatal_message('Failed to FTP->binary! %', $ftp->message);

    my $tar_path = $self->tar_path;
    $self->status_message('TAR path: %s', $tar_path);
    my $tar_path_size = -s $tar_path;
    $self->status_message('TAR size: %s', $tar_path_size);

    if ( not $ftp->put($tar_path) ) {
        $self->fatal_message('Failed to FTP->put! %s', $ftp->message);
    }

    my $tar_file_name = File::Basename::basename($tar_path);
    my $ncbi_size = $ftp->size($tar_file_name);
    if ( not $ncbi_size ) {
        $self->fatal_message('FTP->put succeeded, but file has no size!');
    }
    elsif ( $ncbi_size != $tar_path_size ) {
        $self->fatal_message('FTP->put succeeded, but file was only partially uploaded!');
    }

    $self->status_message('FTP to NCBI...OK');
}

sub _send_mail {
    my $self = shift;
    return 1;
    my $email_ncbi = $self->submission->email_ncbi;

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

    my $to = 'genomes@ncbi.nlm.nih.gov';
    $to = 'submissions@genome.wustl.edu';
    $self->status_message("Sending email to %s", $to);
    my $msg = MIME::Lite->new(
        To => [ $to ],
        Cc => [qw/ submissions@genome.wustl.edu /],
        From => 'submissions@genome.wustl.edu',
        Subject => $mail_subject,
        Type     => 'multipart/mixed'
    ) or die "Can't create Mail::Sender";

    $msg->attach(
        Type =>'TEXT',
        Data => $mail_message,
    );

    $msg->send;
}

sub mail_subject {
    my $self = shift;

    my %h = $self->submission->query_bioproject(
        'Organism_Name',
        'Project_Title'
    );

    unless ($h{'Project_Title'}) {
        die
          "[err] Did not find a 'Project_Title' for GenBank Assembly Submission - ",
          'gas_id: ',
          $self->submission->gas_id, ' (',
          'bioproject_id: ',
          $self->submission->bioproject_id, ' ',
          'creation_event_id: ',
          $self->submission->creation_event_id, ")\n";
    }

    unless ($h{'Organism_Name'}) {
        die
          "[err] Did not find a 'Organism_Name' for GenBank Assembly Submission - ",
          'gas_id: ',
          $self->submission->gas_id, ' (',
          'bioproject_id: ',
          $self->submission->bioproject_id, ' ',
          'creation_event_id: ',
          $self->submission->creation_event_id, ")\n";
    }

    my ($org_name, $prj_title) = @h{'Organism_Name', 'Project_Title'};
    my $bioproject_id = $self->submission->bioproject_id;

    my $subject = "New '$org_name' - '$prj_title' [BioProject: $bioproject_id] assembly submission";
    return $subject;
}

sub mail_message {
    my $self = shift;

    my %h = $self->submission->query_bioproject(
        'Organism_Name', 'Organism_Strain', 'Project_Title');
    die unless %h;

    my $bioproject_id = $self->submission->bioproject_id;
    my $biosample_id = $self->submission->biosample_id;
    my $release_date  = $self->submission->release_date;
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

1;
