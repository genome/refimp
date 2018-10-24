package Tenx::Util::Command::Run::Summary;

use strict;
use warnings 'FATAL';

use Hash::Merge;
use IO::String;
use Path::Class;
use Tenx::Util::Reader::Factory;
use Tenx::Util::Run;
use Text::CSV;
use UTIL::Tablizer;

class Tenx::Util::Command::Run::Summary {
    is => 'Command::V2',
    has => {
        directories => {
            is => 'Text',
            is_many => 1,
            shell_args_position => 1,
            doc => 'TenX run directories for longranger, supernova, or cellranger',
        },
        as => {
            is => 'Text',
            default_value => 'table',
            valid_values => [qw/ csv table yaml /],
        },
    },
    has_optional_transient => {
        run_cnt => { is => 'Integer', },
    },
};

sub execute {
    my ($self) = @_;
    my @runs = map { Tenx::Util::Run->new( dir($_) ) } $self->directories;
    $self->run_cnt( scalar @runs );
    my $summaries = $self->merge_runs(@runs);
    my $output_method = join('_', 'generate', $self->as);
    print $self->$output_method($summaries);
}

sub generate_csv {
    my ($self, $summaries) = @_;
    $self->fatal_messge('No summaries given to generate csv!') if not $summaries;

    my $csv = Text::CSV->new({ sep_char => ',' });
    my $io = IO::String->new;
    my @column_names = sort keys %$summaries;
    $csv->combine(@column_names);
    $io->print( $csv->string()."\n" );

    my $run_cnt = scalar( @{$summaries->{$column_names[0]}} );

    for (my $i = 0; $i < $self->run_cnt; $i++ ) {
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

sub generate_table {
    my ($self, $summaries) = @_;
    $self->fatal_messge('No summaries given to generate table!') if not $summaries;

    my @column_names = sort grep { $_ ne '' } keys %$summaries;
    my @rows = ([ map { uc } @column_names ]);
    for (my $i = 0; $i < $self->run_cnt; $i++ ) {
        my @row;
        for my $key ( @column_names ) {
            push @row, ( ref $summaries->{$key} ) ? $summaries->{$key}->[$i] : $summaries->{$key};
        }
        push @rows, \@row;
    }
    Util::Tablizer->format(\@rows);
}

sub generate_yaml {
    $_[0]->fatal_messge('No summaries given to generate yaml!') if not $_[1];
    YAML::Dump($_[1]);
}

sub merge_runs {
    my ($self, @runs) = @_;
    $self->fatal_message('No runs given to merge!') if not @runs;

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
