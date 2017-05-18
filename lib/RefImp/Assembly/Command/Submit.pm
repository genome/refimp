package RefImp::Assembly::Command::Submit;

use strict;
use warnings 'FATAL';

use File::Temp;
use MIME::Lite;
use Path::Class qw/ dir file /;
use RefImp::Resources::NcbiFtp;

class RefImp::Assembly::Command::Submit {
    is => 'Command::V2',
    has_input => {
        submission_yml => {
            is => 'Text',
            doc => 'YAML file with submission info. It must be in the assembly submission directory. Use the "submission-yaml" command for a template.',
        },
    },
    has_optional_transient => {
        submission => { is => 'RefImp::Project::Submission', },
        tbl2asn_cmd => { is => 'RefImp::Assembly::Command::Submission::TblToAsn', },
        tempdir => { is => 'Path::Class', },
    },
    has_optional_calculated => {
        tar_file => {
            is => 'Path::Class',
            calculate_from => [qw/ tempdir submission /],
            calculate => q| $tempdir->file($submission->ncbi_version.'.tar'); |,
        },
    },
    doc => 'submit a assembly to NCBI',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message('Submit assembly...');

    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    $self->tempdir( Path::Class::dir($tempdir) );
    $self->_create_submission_record;
    $self->_create_sqn_files;
    $self->_create_submission_tar;
    $self->_ftp_to_ncbi;
    $self->_send_mail;

    $self->status_message('Submit assembly...OK');
    1;
}

sub _create_submission_record {
    my $self = shift;

    use RefImp::Assembly::Submission;
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

sub _create_sqn_files {
    my $self = shift;
    $self->status_message('Create SQN files with TBL2ASN...');

    my $tbl2asn = RefImp::Assembly::Command::Submission::TblToAsn->execute(
        submission => $self->submission,
        output_directory => $self->tempdir,
    );
    $self->fatal_message("Failed to run TBL to ASN!") if not $tbl2asn->result;
    $self->tbl2asn_cmd($tbl2asn);
    $self->status_message('Create SQN files with TBL2ASN...OK');
}

sub _create_submission_tar {
    my $self = shift;
    $self->status_message('Create submission TAR...');

    # Create w/ SQN files
    my $tar_file = $self->tar_file;
    $self->status_message('TAR file: %s', $tar_file);
    my $results_path = $self->tbl2asn_cmd->results_path;
    my @sqn_file_names = map { file($_)->basename } $self->tbl2asn_cmd->sqn_files;
    my @tar_cmd = ( "tar", "--create", "--directory", $results_path, "--file", $tar_file, @sqn_file_names );
    $self->status_message('Creating TAR with SQN files...');
    $self->status_message('Running: %s', join(' ', @tar_cmd));
    my $rv = system(@tar_cmd);
    $self->fatal_message('Failed to run tbl2asn: %s', $!) if $rv != 0;

    # Append AGP file
    my $agp_file = $self->submission->info_for('agp_file');
    if ( $agp_file ) {
        my @tar_cmd = ( "tar", "--append", "--directory", $self->submission->directory, "--file", $tar_file, $agp_file );
        $self->status_message('Running: %s', join(' ', @tar_cmd));
        $rv = system(@tar_cmd);
        $self->fatal_message('Failed to run tbl2asn: %s', $!) if $rv != 0;
    }

    $self->status_message('Create submission TAR...OK');
}

sub _ftp_to_ncbi {
    my $self = shift;
    $self->status_message('FTP to NCBI...OK');

    my $ftp = RefImp::Resources::NcbiFtp->connect;
    $self->status_message('Entering remote directory TEMP');
    $ftp->cwd('TEMP') or $self->fatal_message('Failed to FTP->cwd! %', $ftp->message);
    $self->status_message('Setting FTP binary mode');
    $ftp->binary or $self->fatal_message('Failed to FTP->binary! %', $ftp->message);

    my $tar_file = $self->tar_file;
    $self->status_message('TAR path: %s', $tar_file);
    my $tar_file_size = -s $tar_file;
    $self->status_message('TAR size: %s', $tar_file_size);

    if ( not $ftp->put($tar_file) ) {
        $self->fatal_message('Failed to FTP->put! %s', $ftp->message);
    }

    my $tar_file_name = $tar_file->basename;
    my $ncbi_size = $ftp->size($tar_file_name);
    $self->status_message('NCBI size: %s', $ncbi_size);
    if ( not $ncbi_size ) {
        $self->fatal_message('FTP->put succeeded, but file has no size!');
    }
    elsif ( $ncbi_size != $tar_file_size ) {
        $self->fatal_message('FTP->put succeeded, but file was only partially uploaded!');
    }

    $self->status_message('FTP to NCBI...OK');
}

sub _send_mail {
    my $self = shift;
    $self->status_message("Send mail to NCBI...");

    my @to = ( 'genomes@ncbi.nlm.nih.gov' );
    $self->status_message("To: %s", join(',', @to));

    my $submission = $self->submission;
    my $project_title = $submission->project_title;
    my $bioproject = $self->submission->bioproject;
    my $species_name = ucfirst $submission->taxon->species_name;

    my $subject = sprintf(
        "New '%s' - '%s' [BioProject: %s] Assembly Submission",
        $species_name,
        $project_title,
        $bioproject,
    );
    $self->status_message("Subject: %s", $subject);

    my $biosample = $self->submission->biosample;
    my $strain_name = $submission->taxon->strain_name || 'NA';
    my $release_date = $self->submission->info_for('release_date');
    my $tar_file = $self->tar_file->basename;

    my $msg = <<MSG;
Greetings!

The McDonnell Genome Institute has submitted a new assembly to GenBank.

  Organism Name: $species_name
  Strain: $strain_name
  Release Date: $release_date

This assembly is being submitted as part of the '$project_title' project
with BioProject ID: [$bioproject] and BioSample [$biosample].
        
Please find [$tar_file] on ftp-private.ncbi.nlm.nih.gov

Sincerely,
MGI Submissions <gen_improv\@gowustl.onmicrosoft.com>
MSG
    $self->status_message("Message:\n%s\n", $msg);

    my $mimelite = MIME::Lite->new(
        To => \@to,
        Cc => [qw/ mgi-submission@gowustl.onmicrosoft.com /],
        From => 'mgi-submission@gowustl.onmicrosoft.com',
        Subject => $subject,
        Type => 'multipart/mixed'
    );

    $mimelite->attach(
        Type => 'TEXT',
        Data => $msg,
    );
    $mimelite->send or $self->warning_message('Failed to send email!');

    $self->status_message("Send mail to NCBI...OK");
}

1;
