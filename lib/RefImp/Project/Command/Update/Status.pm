package RefImp::Project::Command::Update::Status;

use strict;
use warnings;

use RefImp;

class RefImp::Project::Command::Update::Status { 
    is => 'RefImp::Project::Command::BaseWithMany',
    has_input => {
        value => {
            is => 'String',
            doc => 'Status to set on the given projects.',
        },
    },
    doc => 'update the status of projects',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message('Update project status...');

    my $status = $self->value;
    $self->status_message('New status: %s', $status);
    for my $project ( $self->projects ) {
        my $old_status = $project->status;
        my $new_status = $project->status($status);
        $self->status_message('Set project %s status from %s to %s',  $project->__display_name__, $old_status, $new_status);
    }

    $self->status_message('Update project status...OK');
    return 1;
}

1;

