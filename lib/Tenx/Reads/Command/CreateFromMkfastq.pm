package Tenx::Reads::Command::CreateFromMkfastq;

use strict;
use warnings 'FATAL';

use Path::Class;

class Tenx::Reads::Command::CreateFromMkfastq {
    is => 'Command::V2',
    has_input => {
        directory => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'Mkfastq output directory. Must include outs subdir with input samplesheet.',
        },
    },
    has_optional_input => {
        targets_path => {
            is => 'Text',
            doc => 'Bed file of targets if reads are exome.',
        },
    },
    doc => 'create longranger reads db entries from mkfastq',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 
    $self->status_message('Create longranger reads from mkfastq...');

    $self->fatal_message('Given targets path does not exist: %s', $self->targets_path) if $self->targets_path and !-s $self->targets_path;

    my $samplesheet = Tenx::Reads::MkfastqRun->create( $self->directory );
    for my $sample_name ( $samplesheet->sample_names ) {
        my $sample_directory = $samplesheet->fastq_directory_for_sample_name($sample_name);
        my $reads = Tenx::Reads->create(
            directory => $sample_directory->stringify,
            sample_name => $sample_name,
        );
        $reads->targets_path($self->targets_path) if $self->targets_path;
        $self->status_message('Created reads: %s', $reads->__display_name__);
    }

    $self->status_message('Create longranger reads from mkfastq...OK');
    1;
}

1;
