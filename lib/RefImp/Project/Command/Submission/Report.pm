package RefImp::Project::Command::Submission::Report;

use strict;
use warnings;

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
    },
    doc => 'generate a report of submision records',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;

    my @submissions = $self->submissions;
    for my $submission ( @submissions ) {
        print $submission->__display_name__."\n";
    }
    1;
}

1;
