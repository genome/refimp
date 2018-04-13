package RefImp::Assembly::Command::Submission::VerifyTgzUploaded;

use strict;
use warnings 'FATAL';

class RefImp::Assembly::Command::Submission::VerifyTgzUploaded {
    is => 'Command::V2',
    has_input => {
        submission => {
            is => 'RefImp::Assembly::Submission',
            shell_args_position => 1,
            doc => 'Submission to check if tar file was uploaded.',
        },
    },
    doc => 'check if the submission tgz was uploaded to ncbi',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    my $ftp = RefImp::Resources::NcbiFtp->connect;
    $self->status_message('Entering remote directory TEMP');
    $ftp->cwd('TEMP') or $self->fatal_message('Failed to FTP->cwd! %', $ftp->message);
    $self->status_message('Setting FTP binary mode');
    $ftp->binary or $self->fatal_message('Failed to FTP->binary! %', $ftp->message);

    $self->status_message('Submission: %s', $self->submission->__display_name__);
    my $tar_file_name = $self->submission->tar_basename;
    $self->status_message('Submission TGZ file: %s', $tar_file_name);

    my $ncbi_size = $ftp->size($tar_file_name);
    if ( not $ncbi_size ) {
        $self->status_message('Submission TGZ file NOT found.');
    }
    else {
        $self->status_message('NCBI size: %s', $ncbi_size);
        $self->status_message('Found submission TGZ file.');
    }
    1;
}

1;
