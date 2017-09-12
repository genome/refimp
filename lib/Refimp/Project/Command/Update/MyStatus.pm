package Refimp::Project::Command::Update::MyStatus;

use strict;
use warnings;

class Refimp::Project::Command::Update::MyStatus { 
    is => 'Refimp::Project::Command::Base',
    has_input => {
        value => {
            is => 'String',
            shell_args_position => 1,
            len => 256,
            doc => 'Status to set on the project user association.',
        },
    },
    has_optional_input => {
        user => {
            is => 'Refimp::User',
            doc => 'The user to associate the my status with. The user must be in the db, plus have claimed the project. Defaults to current ENV user.',
        },
    },
    doc => 'update the my status of a project',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message('Update project my status...');

    $self->_resolve_user;

    my $project_finisher = $self->project->project_finishers(user => $self->user);
    if ( not $project_finisher ) {
        $self->fatal_message('No project finisher found for %s', $self->user->__display_name__);
    }

    $self->status_message('Project: %s', $self->project->__display_name__);
    $self->status_message('User: %s', $self->project->__display_name__);
    $project_finisher->status($self->value);
    $self->status_message('Set status: %s', $self->value);

    1;
}

sub _resolve_user {
    my $self = shift;

    return if $self->user;

    $self->fatal_message('No ENV user set to resolve to set my status for!') if not $ENV{USER};

    my $user = Refimp::User->get(name => $ENV{USER});
    $self->fatal_message('No user found for %s', $ENV{USER});

    $self->user($user);

}

1;
