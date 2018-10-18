package Tenx::Util::Run::Report::Summary;

use strict;
use warnings 'FATAL';

use Hash::Merge;
use IO::String;
use Tenx::Util::Reader::Factory;
use Text::CSV;

sub generate_yaml { YAML::Dump( _consolidate_runs(@_) ) }

sub generate_csv {
    my ($class, @runs) = @_;

    my $summaries = $class->_consolidate_runs(@runs);

    my $csv = Text::CSV->new({ sep_char => ',' });
    my $io = IO::String->new;
    my @column_names = sort keys %$summaries;
    $csv->combine(@column_names);
    $io->print( $csv->string()."\n" );

    for (my $i = 0; $i < @runs; $i++ ) {
        my @row;
        for my $key ( @column_names ) {
            push @row, $summaries->{$key}->[$i];
        }
        my $status = $csv->combine(@row);
        my $line   = $csv->string();     
        $io->print("$line\n");
    }

    $io->seek(0, 0);
    join('', $io->getlines);
}

sub _consolidate_runs {
    my ($class, @runs) = @_;

    die "No runs given to generate summary report!" if not @runs;

    my @summaries;
    my $csv = Text::CSV->new({ sep_char => ',' });
    for my $run ( @runs ){
        my $summary_csv = $run->summary_csv;
        warn "No summary csv for run ".$run->location if not 

        my $reader = Tenx::Util::Reader::Factory->build_reader($run->summary_csv);
        my $io = $reader->handle;
        my $column_names = $csv->getline ($io);   
        die "No column names found in $summary_csv" if not $column_names;
        $csv->column_names(@$column_names);

        my $summary = $csv->getline_hr($io);
        die "No data found in $summary_csv" if not $summary;
        push @summaries, $summary;
    }

    Hash::Merge::set_behavior('RETAINMENT_PRECEDENT');
    Hash::Merge::merge(@summaries)

}

1;
