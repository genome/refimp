package Refimp::Project::Command::BaseWithMany;

use strict;
use warnings;

use Refimp::Role::PropertyValuesFromFile;

class Refimp::Project::Command::BaseWithMany { 
    is => 'Command::V2',
    is_abstract => 1,
    has_input => {
        projects => {
            is => 'Refimp::Project',
            is_many => 1,
            shell_args_position => 1,
            require_user_verify => 0,
            doc => 'Projects to use. Use ids, names, or filter on other properties.',
        },
    },
    doc => 'base class for commands that work with many projects',
};
Refimp::Role::PropertyValuesFromFile::class_properties_can_load_from_file(__PACKAGE__, 'projects');

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    $self->_before_execute;

    for my $project ( $self->projects ) {
        $self->_execute_with_project($project);
    }

    $self->_after_execute;
}

sub _before_execute { 1 }
sub _execute_with_project { die "Implement _execute_with_project!" }
sub _after_execute { 1 }

1;

