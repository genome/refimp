package Tenx::Reads::Command::UploadToCloud;

use strict;
use warnings 'FATAL';

use Path::Class;
use Util::GCP;

class Tenx::Reads::Command::UploadToCloud {
    is => 'Command::V2',
    has_input => {
        directory => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'Mkfastq output directory. Must include outs subdir with input samplesheet.',
        },
        destination => {
            is => 'Text',
            shell_args_position => 2,
            doc => 'Destination in the cloud. Include the protocol like gs://, etc.',
        },
    },
    has_optional_input => {
        samples => {
            is => 'Text',
            is_many => 1,
            doc => 'List of samples to upload. Default to is upload all in sample sheet.',
        },
    },
    doc => 'send reads to the cloud',
};

sub help_detail { "Send reads from mkfastq run to the cloud. You must first authorize your GCP account with 'gcloud init' or 'gcloud auth'." }

sub execute {
    my $self = shift; 
    $self->status_message('Upload to cloud...');

    my $destination = $self->destination;
    $destination =~ s#/$##;
    $self->fatal_message('Unknown destination: %s', $self->destination) if $destination !~ m#^gs://#;

    my $samplesheet = Tenx::Reads::MkfastqRun->create( $self->directory );
    for my $sample_name ( $samplesheet->sample_names ) {
        if ( $self->samples && ! List::Util::any { $sample_name eq $_ } $self->samples ) {
            $self->status_message('Skipping %s not in given samples white list.', $sample_name);
            next;
        }
        $self->status_message('Uploading %s ...', $sample_name);
        my $sample_directory = $samplesheet->fastq_directory_for_sample_name($sample_name);
        my $destination_sample_dir = $destination.'/'.$sample_name;
        Util::GCP->rsync("$sample_directory", "$destination_sample_dir");
    }

    $self->status_message('Upload to cloud...OK');
    1;
}

1;
