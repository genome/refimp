package Refimp::Project::Command::Submission::Report;

use strict;
use warnings;

use Refimp::Util::Tablizer;
use YAML;

class Refimp::Project::Command::Submission::Report { 
    is => 'Command::V2',
    has_input => {
        submissions => {
            is => 'Refimp::Project::Submission',
            is_many => 1,
            shell_args_position => 1,
            require_user_verify => 0,
            doc => 'Submissions to generate the report.',
        },
        type => {
            is => 'Text',
            valid_values => [qw/ general finisher /],
            default_value => 'general',
            doc => 'Type of report to display.',
        },
    },
    doc => 'generate a report of submission records',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;
    my $type = $self->type;
    $self->$type;
}

sub general {
    my $self = shift;

    my @rows = [qw/ Project Finisher Date Size  /];
    push @rows, [ map { '-' x length } @{$rows[0]} ];
    my %metrics;
    for my $submission ( $self->submissions ) {
        $metrics{'Number of Projects'}++;
        my $size = $submission->project_size || 0;
        $metrics{'Total Size'} += $size;
        push @rows, [ $submission->project->name, (map { $_->name } $submission->project->finishers)[0], $submission->submitted_on, $size, ];
    }
    print Refimp::Util::Tablizer->format(\@rows).YAML::Dump(\%metrics);
}

sub finisher {
    my $self = shift;

    my %finishers;
    for my $submission ( $self->submissions ) {
        my ($finisher) = map { $_->name } $submission->project->finishers;
        $finishers{$finisher}->{metrics}->{'Number of Projects'}++;
        my $size = $submission->project_size || 0;
        $finishers{$finisher}->{metrics}->{'Total Size'} += $size;
        push @{$finishers{$finisher}->{rows}}, [ $submission->project->name, $submission->submitted_on, $size, ];
    }

    my $headers = [qw/ Project Date Size  /];
    my @output;
    for my $finisher ( sort keys %finishers ) {
        my $rows = $finishers{$finisher}->{rows};
        unshift @$rows, $headers, [ map { '-' x length } @$headers ];
        my %metrics = %{$finishers{$finisher}->{metrics}};
        $metrics{Finisher} = $finisher;
        push @output, Refimp::Util::Tablizer->format($finishers{$finisher}->{rows}).YAML::Dump(\%metrics);
    }
    print join("\n", @output);
}

1;
