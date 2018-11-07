package Tenx::Reads::Command::QcSummary;

use strict;
use warnings 'FATAL';

use Util::Tablizer;

class Tenx::Reads::Command::QcSummary {
    is => 'Command::V2',
    has_input => {
        directory => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'Mkfastq output directory. Must include outs subdir with qc_summary.json file.',
        },
    },
    has_optional_param => {
        show_all => {
            is => 'Boolean',
            doc => 'Show all lanes, otherwise jsut show all lanes summarized.',
        },
    },
    doc => 'show samples qc',
};

sub help_detail { 'Show sample QC from the outs/qc_summary.json file for a mkfastq run.' }

sub execute {
    my $self = shift; 

    my $samplesheet = Tenx::Reads::MkfastqRun->create($self->directory);
    my $qc_summary = $samplesheet->qc_summary;
    my $qcs = $qc_summary->{sample_qc};
    $self->fatal_message("Failed to find sample_qc key in qc_sdummary JSON!") if not $qcs;

    my (@headers, @rows);
    for my $sample_name ( $samplesheet->sample_names ) {
        if ( not exists $qcs->{$sample_name} ) {
            $self->warning_message('No sample qc for %s', $sample_name);
            next;
        }
        my $sample_qc = $qcs->{$sample_name};
        for my $lane ( $self->show_all ? keys(%{$sample_qc}) : 'all' ) {
            push @headers, keys %{$sample_qc->{$lane}};
            my @row = ( map { sprintf('%0.2f', $_) } map { $sample_qc->{$lane}->{$_} } sort {$a cmp $b } keys %{$sample_qc->{$lane}} );
            unshift @row, $lane if $self->show_all;
            unshift @row, $sample_name;
            push @rows, \@row;
        }
    }

    @headers = map { uc } sort { $a cmp $b } List::Util::uniq(@headers);
    unshift @headers, 'LANE' if $self->show_all;
    unshift @headers, 'SAMPLE';
    my @dashes = map { '-' x length($_) } @headers;
    unshift @rows, \@headers, \@dashes;

    print Util::Tablizer->format(\@rows);
    1;
}

1;
