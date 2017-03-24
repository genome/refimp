package RefImp::Project::Command::Claim;

use strict;
use warnings 'FATAL';

use RefImp::Project::User;

class RefImp::Project::Command::Claim {
    is => 'RefImp::Project::Command::Base',
    has_input => {
        as => {
            is => 'Text',
            valid_values => [ RefImp::Project::User->valid_purposes ],
            shell_args_position => 2,
            doc => 'Claim the project as this function.',
        },
        unix_login => {
            is => 'Text',
            shell_args_position => 3,
            doc => 'Claim the project for this user.',
        },
        project_status => {
            is => 'Text',
            doc => 'Additionally, update the status on the project.',
        },
    },
    doc => 'claim a project as finisher/prefinisher/saver',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message('Claim...');

    my $project = $self->project;
    $self->status_message('Project: %s', $project->__display_name__);
    $self->status_message('Current status: %s', $project->status);

    my $user = RefImp::User->get(name => $self->unix_login);
    $self->fatal_message('No user for unix_login: %s', $self->unix_login) if not $user;
    $self->status_message('Function: %s', $self->as);
    $self->status_message('User: %s', $user->name);

    my $claimer = RefImp::Project::User->create(
        project => $project,
        user => $user,
        purpose => $self->as,
    );

    if ( $self->project_status ) {
        $self->status_message('Updated project status: %s', $project->status( $self->project_status) );
    }

    $self->status_message('Claim...OK');
    return 1;
}

1;

