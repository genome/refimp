package RefImp::Project::Command::Update::Directory;

use strict;
use warnings;

use Cwd 'abs_path';
use File::Path;
use File::Spec;
use RefImp::Util::Tablizer;

class RefImp::Project::Command::Update::Directory { 
    is => 'RefImp::Project::Command::BaseWithMany',
    has_input => {
        value => {
            is => 'String',
            doc => 'Base directory to use in combination with the project name to resolve and as the project directory.',
        },
    },
    has_optional => {
        old_values => { is => 'ARRAY', default_value => [], },
    },
    doc => 'update the file system location of projects',
};

sub help_detail { $_[0]->__meta__->doc }

sub _before_execute {
    my $self = shift;
    $self->value( abs_path($self->value) );
    $self->fatal_message('Base directory does not exist!') if not -d $self->value;
}

sub _execute_with_project {
    my ($self, $project) = @_;

    push @{$self->old_values}, ( $project->directory // 'NULL' );
    my $directory = File::Spec->join($self->value, $project->name);
    if ( not -d $directory ) {
        File::Path::mkpath($directory);
        $self->fatal_message('Failed to make project directory: %s', $directory) if not -d $directory;
    }
    $project->directory($directory);
}

sub _after_execute {
    my $self = shift;

    my @rows = (
        [qw/ ID NAME DIRECTORY OLD_DIRECTORY /],
        [qw/ -- ---- --------- ------------- /],
    );

    my $old_values = $self->old_values;
    my $i = 0;
    for my $project ( $self->projects ) {
        push @rows, [ map({ $project->$_ } (qw/ id name directory /)), $old_values->[$i] ];
        $i++;
    }

    print RefImp::Util::Tablizer->format(\@rows);
}

1;
