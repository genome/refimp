package Tenx::Alignment::Command::StatSummary;

use strict;
use warnings 'FATAL';

use Path::Class;
use Text::CSV;
use YAML;

class Tenx::Alignment::Command::StatSummary {
    is => 'Command::V2',
    has_input => {
        directory => {
            is => 'Text',
        },
    },
    has_calculated_constant_optional => {
        _directory => { calculate_from => [qw/ directory /], calculate => q| Path::Class::dir($directory) |, },
        summary_file => { calculate_from => [qw/ _directory /], calculate => q| $_directory->subdir('outs')->file('summary.csv') |, },
    },
    doc => 'display the longranger summary in a readable format',
};

sub help_detail {
    return <<HELP;

Loads the outs/summary.csv file from a succeeded longranger run and displays it as YAML.

HELP
}

sub execute {
    my $self = shift;

    $self->status_message('Alignment Run Stat Summary...');
    my $summary_file = $self->summary_file;
    $self->status_message('Summary file: %s', $summary_file->stringify);
    $self->fatal_message(
        'Summary file does not exist! Has the longranger run succeeded? Check with "tenx alignment status --h"'
    ) if not -s $summary_file;

    my $fh = IO::File->new($summary_file->stringify);
    $self->fatal_message('Failed to open summary file!') if not $fh;

    my $csv = Text::CSV->new({sep_char => ','});
    $self->fatal_message('Failed to create Text::CSV object!') if not $csv;

    my $column_names = $csv->getline($fh);
    $self->fatal_message('Could not read column names form summary file!') if not $column_names;
    $csv->column_names(@$column_names);

    my $stats = $csv->getline_hr($fh);
    $self->fatal_message('Could not read stats from summary file!') if not $stats;
    $self->status_message( YAML::Dump($stats) );

    1;
}

1;
