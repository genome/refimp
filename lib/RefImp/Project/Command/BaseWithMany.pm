package RefImp::Project::Command::BaseWithMany;

use strict;
use warnings;

use RefImp;

class RefImp::Project::Command::BaseWithMany { 
    is => 'Command::V2',
    is_abstract => 1,
    has_input => {
        projects => {
            is => 'RefImp::Project',
            is_many => 1,
            shell_args_position => 1,
            doc => 'Projects to use. Use ids, names, or filter on other properties.',
        },
    },
};

sub execute {
    my $self = shift;

    $self->_before_execute;
    for my $project ( $self->projects ) {
        $self->_execute_with_project($project);
    }
    $self->_after_execute;

    return 1;
}

sub _before_execute { 1 }
sub _execute_with_project { die "Implement _execute_with_project!" }
sub _after_execute { 1 }

1;

