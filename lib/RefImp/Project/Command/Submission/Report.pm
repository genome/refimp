package RefImp::Project::Command::Submission::Report;

use strict;
use warnings;

use RefImp::Util::Tablizer;
use YAML;

class RefImp::Project::Command::Submission::Report { 
    is => 'Command::V2',
    has_input => {
        submissions => {
            is => 'RefImp::Project::Submission',
            is_many => 1,
            shell_args_position => 1,
            require_user_verify => 0,
            doc => 'Submissions to generate the report.',
        },
        type => {
            is => 'Text',
            valid_values => [qw/ general /],
            default_value => 'general',
            doc => 'Type of report to display.',
        },
    },
    doc => 'generate a report of submision records',
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
        $metrics{'Total Size'} = $size;
        push @rows, [ $submission->project->name, join(',', map { $_->name } $submission->project->finishers), $submission->submitted_on, $size, ];
    }
    print RefImp::Util::Tablizer->format(\@rows).YAML::Dump(\%metrics);
}

1;
