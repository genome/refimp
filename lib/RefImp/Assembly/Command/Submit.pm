package RefImp::Assembly::Command::Submit;

use strict;
use warnings 'FATAL';

use Date::Format;
use File::Temp;
use Path::Class qw/ dir file /;
use RefImp::Resources::NcbiFtp;

class RefImp::Assembly::Command::Submit {
    is => 'Command::V2',
    has_input => {
        submission_yml => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'YAML file with submission info. It must be in the assembly submission directory. Use the "refimp assembly submission yaml" command for a template or help (--h).',
        },
    },
    has_optional_transient => {
        submission => { is => 'RefImp::Project::Submission', },
        tempdir => { is => 'Path::Class', },
        tar_file => { is => 'Path::Class::file', },
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
    $self->_create_submission_tar;
    $self->_ftp_to_ncbi;
    $self->_print_mail;

    $self->status_message('Submit assembly...OK');
    1;
}

sub _create_submission_record {
    my $self = shift;

    use RefImp::Assembly::Submission;
    my $submission = RefImp::Assembly::Submission->get_or_create_from_yml($self->submission_yml);
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
    my $cmd = RefImp::Assembly::Command::Submission::CreateTar->create(
        submission_yml => $self->submission_yml,
        output_directory => $self->tempdir->stringify,
    );
    $self->fatal_message("Failed to create submission TAR!") if not $cmd->execute or not $cmd->result;
    $self->tar_file($cmd->tar_file);
}

sub _ftp_to_ncbi {
    my $self = shift;
    $self->status_message('FTP to NCBI...');

    my $ftp = RefImp::Resources::NcbiFtp->connect;
    $self->status_message('Entering remote directory TEMP');
    $ftp->cwd('TEMP') or $self->fatal_message('Failed to FTP->cwd! %', $ftp->message);
    $self->status_message('Setting FTP binary mode');
    $ftp->binary or $self->fatal_message('Failed to FTP->binary! %', $ftp->message);

    my $tar_file = $self->tar_file;
    $self->status_message('TAR path: %s', $tar_file);
    my $tar_file_size = -s $tar_file;
    $self->status_message('TAR size: %s', $tar_file_size);

    my $tar_file_name = $tar_file->basename;
    $self->status_message('TAR basename: %s', $tar_file_name);

    if ( not $ftp->put("$tar_file", "$tar_file_name") ) {
        $self->fatal_message('Failed to FTP->put! %s', $ftp->message);
    }

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

sub _print_mail {
    my $self = shift;
	$self->status_message("#########################################################\n");
    $self->status_message("          Please send the below message to NCBI\n");
    $self->status_message("#########################################################\n");
    RefImp::Assembly::Command::Submission::Email->execute(submission => $self->submission);
    $self->status_message("#########################################################\n");
}

1;
