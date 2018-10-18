package Tenx::Reads::Command::Fastqs;

use strict;
use warnings 'FATAL';

use Util::Tablizer;

class Tenx::Reads::Command::Fastqs {
    is => 'Command::V2',
    has_input => {
        directory => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'Mkfastq output directory. Must include outs subdir with input samplesheet.',
        },
    },
    doc => 'show samples and fastq paths',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 

    my $samplesheet = Tenx::Reads::MkfastqRun->create($self->directory);
    my @rows = ([qw/ SAMPLE FASTQ_PATH /]);
    push @rows, [ map { '-' x length($_) } @{$rows[0]} ];
    for my $sample_name ( $samplesheet->sample_names ) {
        my $sample_directory = $samplesheet->fastq_directory_for_sample_name($sample_name);
        push @rows, [ $sample_name, $sample_directory ];
    }

    print Util::Tablizer->format(\@rows);
    1;
}

1;
