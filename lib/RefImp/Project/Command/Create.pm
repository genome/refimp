package RefImp::Project::Command::Create;

use strict;
use warnings;

use RefImp::Role::PropertyValuesFromFile;

class RefImp::Project::Command::Create { 
    is => 'Command::V2',
    has_input => {
        names => {
            is => 'Text',
            is_many => 1,
            doc => 'Names of the projects.',
        },
    },
    has_optional_input => {
        chromosome => {
            is => 'Text',
            default_value => 'unknown',
            doc => 'The chromosome to assign to the project\'s taxonomy.',
        },
        directory => {
            is => 'Text',
            doc => 'Base directory to create project structure in.',
        },
        status => {
            is => 'Text',
            default_value => 'prefinish_start',
            doc => 'Starting status of the project.',
        },
        taxon => {
            is => 'RefImp::Taxon',
            doc => 'The taxon to assign to the project. Deafult is to set as an unknown organism.',
        },
    },
    doc => 'create a project',
};
RefImp::Role::PropertyValuesFromFile::class_properties_can_load_from_file(__PACKAGE__, 'names');

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 
    $self->status_message('Create projects...');

    my $directory_updater = RefImp::Project::Command::Update::Directory->create(value => $self->directory) if $self->directory;
    my $taxonomy_params = $self->_resolve_taxonomy_params;
    my $taxonomy_updater = RefImp::Project::Command::Update::Taxonomy->create(%$taxonomy_params);

    for my $name ( $self->names ) {
        my $project = $self->_get_or_create_project($name);
        $project->status($self->status);
        if ( $directory_updater ) {
            $directory_updater->_execute_with_project($project);
        }
        $taxonomy_updater->_execute_with_project($project);
        $self->status_message( join(' ', $project->__display_name__, $project->status, ($project->directory || 'NA')) );
    }

    $directory_updater->delete if $directory_updater;
    $taxonomy_updater->delete;

    return 1;
}

sub _resolve_taxonomy_params {
    my $self = shift;

    my $taxon = $self->taxon;
    if ( not $taxon ) {
        $taxon = RefImp::Taxon->get(name => 'unknown');
        $self->fatal_message('Failed to get "unknown" taxon!') if not $taxon;
    }

    my %params = (
        taxon => $taxon,
        chromosome => $self->chromosome,
    );

    return \%params;
}

sub _get_or_create_project {
    my ($self, $name) = @_;

    my $project = RefImp::Project->get(name => $name);
    return $project if $project;

    my %params = (
        name => $name,
    );
    $project = RefImp::Project->create(%params);
    $self->fatal_message('Failed to create project!') if !$project;

    $project;
}

1;

