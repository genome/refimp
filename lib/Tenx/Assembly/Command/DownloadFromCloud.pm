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
    has_output => {
        destination => {
            is => 'Text',
            shell_args_position => 2,
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
    my $assembly_url = $assembly->url;
    $self->fatal_message('Unknown assembly cloud source: %s. Is the assembly on the cloud?', $assembly_url) if $assembly_url !~ m#^gs://#;
    $assembly_url =~ s#/*$##;

    my $destination = dir($self->destination)->subdir($assembly->name);
    $self->fatal_message("Local destination exists: %s", $destination) if -d "$destination";
    mkpath("$destination") or $self->fatal_message('Failed to mkpath: %s', $destination);

    for my $bn (qw/ _log /) {
        my $src = sprintf('%s/%s', $assembly_url, $bn);
        Util::GCP->cp($src, "$destination");
    }

    $destination = $destination->subdir('outs');
    mkpath("$destination") or $self->fatal_message('Failed to mkpath: %s', $destination);
    for my $bn (qw/ report.txt summary.csv /) {
        my $src = sprintf('%s/outs/%s', $assembly_url, $bn);
        Util::GCP->cp($src, "$destination");
    }

    $destination = $destination->parent->subdir('mkoutput');
    mkpath("$destination") or $self->fatal_message('Failed to mkpath: %s', $destination);
    for my $type ( RefImp::Assembly->mkoutput_types ) {
        my $src = sprintf('%s/mkoutput/%s.%s.*fasta.gz', $assembly_url, $assembly->name, $type);
        Util::GCP->cp($src, "$destination");
    }

    $self->status_message('Download assembly from cloud...OK');
    1;
}

1;
