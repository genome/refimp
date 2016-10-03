package RefImp::Project::Command::Update::Directory;

use strict;
use warnings;

use Cwd 'abs_path';
use File::Path;
use File::Spec;

class RefImp::Project::Command::Update::Directory { 
    is => 'RefImp::Project::Command::BaseWithMany',
    has_input => {
        value => {
            is => 'String',
            doc => 'Base directory to use in combination with the project name to resolve and as the project directory.',
        },
    },
    doc => 'update the file system location of projects',
};

sub help_detail { $_[0]->__meta__->doc }

sub _before_execute {
    my $self = shift;
    $self->status_message('Update project(s) directory...');
    $self->value( abs_path($self->value) );
    $self->status_message('Base Directory: %s', $self->value);
    $self->fatal_message('Base directory does not exist!') if not -d $self->value;
}

sub _execute_with_project {
    my ($self, $project) = @_;

    $self->status_message('Project: %s', $project->__display_name__);
    $self->status_message('Old directory: %s', ($project->directory // 'UNDEF'));
    my $directory = File::Spec->join($self->value, $project->name);
    if ( not -d $directory ) {
        File::Path::mkpath($directory);
        $self->fatal_message('Failed to make project directory: %s', $directory) if not -d $directory;
    }
    $self->status_message('New Directory: %s', $directory);

    $project->directory($directory);
}

sub _after_execute {
    my $self = shift;
    $self->status_message('Update project(s) directory...OK');
}

1;

