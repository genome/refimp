package Refimp::Project::Command::Submission::QaBase;

use strict;
use warnings;

use List::MoreUtils 'any';

class Refimp::Project::Command::Submission::QaBase {
    is => 'Refimp::Project::Command::Base',
    is_abstract => 1,
};

sub _check_project_status {
    my $self = shift;

    my $status = $self->project->status;
    $self->status_message('Current project status: %s', $status);
    if ( not any { $status eq $_ } $self->valid_project_statuses ) {
        $self->fatal_message('Project has incorrect status. Needs to be: %s', join(' ', $self->valid_project_statuses));
    }
}

1;

