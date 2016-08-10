package RefImp::Project::Command::Claim;

use strict;
use warnings;

use RefImp;

class RefImp::Project::Command::Claim {
    is => 'RefImp::Project::Command::Base',
    has_input => {
        as => {
            is => 'String',
            valid_values => [qw/ finisher prefinisher saver /],
            shell_args_position => 2,
            doc => 'Claim the project as this function.',
        },
        unix_login => {
            is => 'String',
            shell_args_position => 3,
            doc => 'Claim the project for this user.',
        },
        update_project_status => {
            is => 'Boolean',
            default_value => 1,
            doc => 'Update the status on the project. ',
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

    my $user = RefImp::User->get(unix_login => $self->unix_login);
    $self->fatal_message('No user for unix_login: %s', $self->unix_login) if not $user;
    $self->status_message('Function: %s', $self->as);
    $self->status_message('User: %s', $user->unix_login);

    my $claimer_class = RefImp::Project::Claimer->class_for_claimer_type( $self->as );
    my $claimer = $claimer_class->create_for_project_and_user(
        project => $project,
        user => $user,
    );

    if ( $self->update_project_status ) {
        $self->_update_project_status;
        $self->status_message('Updated project status: %s', $project->status);
    }

    $self->status_message('Claim...OK');
    return 1;
}

sub _update_project_status {
    my $self = shift;
    my $function_for_claim_type = RefImp::Project::Claimer->function_for_claim_type( $self->as );
    my $status = $function_for_claim_type.'_start';
    $self->project->status($status);
}

1;

