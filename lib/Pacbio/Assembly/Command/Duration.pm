package Pacbio::Assembly::Command::Duration;

use strict;
use warnings 'FATAL';

use DateTime::Format::Duration;
use Pacbio::Assembly::Run;

class Pacbio::Assembly::Command::Duration {
    is => 'Command::V2',
    has_input => {
        assembly => {
            is => 'Text',
            doc => 'Assembly directory with log files.',
        },
    },
    has_output => {
        output_file => {
            is => 'Text',
            default_value => '-',
            doc => 'primary contigs fasta file.',
        },
    },
    has_optional_param => {
        detail => {
            is => 'Boolean',
            doc => '',
        },
    },
    has_optional_transient => {
        _run => { is => 'Pacbio::Assebmly::Run', },
    },
    doc => 'calculate the stage durations for an assembly',
};

sub execute {
    my ($self) = @_;

    my $run = Pacbio::Assembly::Run->new($self->assembly);
    my $stages = $run->get_stages;
    my $total = 0;
    my $formatter = DateTime::Format::Duration->new(pattern => '%dd %Hh %Mm %Ss', normalize => 1);
    for my $stage ( sort keys %$stages ) {
        $total += $stages->{$stage}->{duration};
        printf("%s %s\n", $stage, $formatter->format_duration_from_deltas(seconds => $stages->{$stage}->{duration}));
        if ( exists $stages->{$stage}->{substages} ) {
            my $substages = $stages->{$stage}->{substages};
            for my $substage ( sort keys %$substages) {
                printf(" %s %s\n",  $substage, $formatter->format_duration_from_deltas(seconds => $substages->{$substage}));
            }
        }
    }
    printf("Total %s\n", $formatter->format_duration_from_deltas(seconds => $total));

    1;
}

1;
