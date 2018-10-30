package Tenx::Reads::Command::UpdateFromMkfastq;

use strict;
use warnings 'FATAL';

use Path::Class;

use Tenx::Util::Run;
use Util::Tablizer;

class Tenx::Reads::Command::UpdateFromMkfastq {
    is => 'Command::V2',
    has_input => {
        directory => {
            is => 'Text',
            shell_args_position => 2,
            doc => 'Mkfastq output directory. Must include outs subdir with input samplesheet.',
        },
    },
    doc => 'update read directories from a new mkfastq location',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 
    $self->status_message('Update reads from mkfastq...');

    my $old_directory = $self->_determine_old_directory;
    my %reads = map { $_->sample_name => $_ } Tenx::Reads->get('directory like' => $old_directory.'%');
    $self->fatal_message('Failed to find reads for OLD mkfastq directory: %s', $old_directory) if not %reads;

    my $samplesheet = Tenx::Reads::MkfastqRun->create( $self->directory );
    my @rows = ([qw/ STATUS SAMPLE OLD NEW /]);
    for my $sample_name ( $samplesheet->sample_names ) {
        my $sample_reads = $reads{$sample_name};
        if ( $sample_reads ) {
            push @rows, [ 'OK', $sample_name, 'NA', 'NA' ];
            my $sample_directory = $samplesheet->fastq_directory_for_sample_name($sample_name);
            $sample_reads->directory("$sample_directory");
        }
        else {
            push @rows, [ 'NOT_IN_DB', $sample_name, 'NA', 'NA' ];
        }
    }

    $self->status_message( Util::Tablizer->format(\@rows) );
    1;
}

sub _determine_old_directory {
    my ($self) = @_;

    my $directory = dir( $self->directory );
    my $run = Tenx::Util::Run->new($directory);
    $self->fatal_message("Failed to create tenx run!") if not $run;

    my $log = $run->log;
    $self->fata_message("Failed to get log from run!") if not $log;

    my $old_input_sample_sheet_path = $log->outputs->{input_samplesheet};
    $self->fatal_message("No 'input_samplesheet' in the run outputs!") if not $old_input_sample_sheet_path;

    file($old_input_sample_sheet_path)->dir->parent->stringify;

}

1;
