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

    my $taxon_params = $self->_resolve_taxon_params;

    for my $name ( $self->names ) {
        my $project = $self->_get_or_create_project($name);

        $self->status_message('Status: %s', $project->status($self->status));
        if ( $self->directory ) {
            RefImp::Project::Command::Update::Directory->execute(
                projects => [$project],
                value => $self->directory,
            );
        }

        RefImp::Project::Command::Update::Taxonomy->execute(
            projects => [$project],
            %$taxon_params,
        );
    }

    return 1;
}

sub _resolve_taxon_params {
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
    if ( $project ) {
        $self->status_message('Found existing project: %s', $project->__display_name__);
        return $project;
    }

    my %params = (
        name => $name,
    );
    $self->status_message("Project params:\n%s---\n", YAML::Dump(\%params));
    $project = RefImp::Project->create(%params);
    $self->fatal_message('Failed to create project!') if !$project;
    $self->status_message('Created project: %s', $project->__display_name__);

    $project;
}

1;

