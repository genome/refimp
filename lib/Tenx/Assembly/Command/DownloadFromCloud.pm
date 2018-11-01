package Tenx::Assembly::Command::DownloadFromCloud;

use strict;
use warnings 'FATAL';

use File::Path 'mkpath';
use Path::Class 'dir';

use Util::GCP;

class Tenx::Assembly::Command::DownloadFromCloud {
    is => 'Command::V2',
    has_input => {
        assembly => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'Remotely stored assembly id or URL.',
        },
    },
    has_optional_input => {
        types => {
            is => 'Text',
            is_many => 1,
            default_value => [ Tenx::Assembly->mkoutput_types ],
            valid_values => [ Tenx::Assembly->mkoutput_types ],
            doc => 'Assembly outputs to download.',
        },
    },
    has_output => {
        destination => {
            is => 'Text',
            doc => 'Directory location to put assembly outputs. A subdirectory with the sample name will be made inside this directory.',
        },
    },
    doc => 'get assembly mkoutputs from the cloud',
};

sub help_detail { "Get assembly outputs from mkoutput from a cloud storage location. You must first authorize your GCP account with 'gcloud init' or 'gcloud auth'." }

sub execute {
    my $self = shift; 
    $self->status_message('Download assembly from cloud...');

    my $assembly = Tenx::Assembly::Command->get_assembly($self->assembly);
    $self->status_message('Assembly: %s', $assembly->__display_name__);
    my $url = $assembly->url;
    $self->fatal_message('Unknown assembly cloud source: %s. Is the assembly on the cloud?', $url) if $url !~ m#^gs://#;

    my $destination = dir($self->destination)->subdir($assembly->sample_name);
    mkpath($destination) or $self->fatal_message('Failed to mkpath: %s', $destination);

    for my $type ( $self->types ) {
        my $src_files = sprintf('%s/mkoutput/%s.%s.*fasta.gz', $assembly->url, $assembly->sample_name, $type);
        Util::GCP->cp($src_files, $destination);
    }

    $self->status_message('Download assembly from cloud...OK');
    1;
}

1;
