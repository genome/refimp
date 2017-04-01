package RefImp::Project::Command::Submission::Create;

use strict;
use warnings;

class RefImp::Project::Command::Submission::Create { 
    is => 'RefImp::Project::Command::Base',
    has_input => {
        phase => {
            default_value => 3,
            doc => 'Project submission phase.',
        },
    },
    has_optional_input => {
        accession_id => {
            is => 'Text',
            doc => 'The accession number assigned by NCBI.',
        },
        directory => {
            is => 'Text',
            doc => 'Directory to use for the submission. If not provided, a date named subdir will be made in the project\'s analysis directory.',
        },
        submitted_on => {
            is => 'Date',
            doc => 'The date of submission. Format: YYYY-MM-DD.',
        },
        create_from_directory => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Create the submssion from the directory provided using the directory name and submit info to construct it.',
         },
    },
    doc => 'create a project submission record',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 
    $self->status_message('Create project submission...');
    my $submission;
    if ( $self->create_from_directory ) {
        $submission = $self->_create_from_directory;
    }
    else {
        $submission = $self->_create_from_params;
    }
    $self->fatal_message('Failed to create submission for %s', $self->project) if not $submission;

    $self->status_message('Created submission: %s', $submission->__display_name__);
    1;
}

sub _create_from_params {
    my $self = shift;
    my %params = (
        project_id => $self->project->id,
        phase => $self->phase,
    );
    $params{directory} = $self->directory if $self->directory;
    $params{submitted_on} = $self->submitted_on if $self->submitted_on;
    $self->status_message('Submission params: %s', YAML::Dump(\%params));

    RefImp::Project::Submission->create(%params);
}

sub _create_from_directory {
    my $self = shift;
    $self->fatal_message('Requested to create submission from directory, but didn\'t provide one!') if not $self->directory;
    RefImp::Project::Submission->create_from_directory($self->directory);
}

1;
