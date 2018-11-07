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
    doc => 'show samples qc',
};

sub help_detail { __PACKAGE__->__meta__->doc }

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
        push @headers, keys %{$sample_qc->{all}};
        push @rows, [ $sample_name, map { sprintf('%0.2f', $_) } map { $sample_qc->{all}->{$_} } sort {$a cmp $b } keys %{$sample_qc->{all}} ];
    }

    @headers = map { uc } sort { $a cmp $b } List::Util::uniq(@headers);
    unshift @headers, 'SAMPLE';
    my @dashes = map { '-' x length($_) } @headers;
    unshift @rows, \@headers, \@dashes;

    print Util::Tablizer->format(\@rows);
    1;
}

1;
