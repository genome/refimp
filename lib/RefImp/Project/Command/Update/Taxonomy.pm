package RefImp::Project::Command::Update::Taxonomy;

use strict;
use warnings;

class RefImp::Project::Command::Update::Taxonomy { 
    is => 'RefImp::Project::Command::BaseWithMany',
    has_input => {
        taxon => {
            is => 'RefImp::Taxon',
            doc => 'Taxon for the project.',
        },
        chromosome => {
            is => 'Text',
            default_value => 'unknown',
            doc => 'Chromosome for the project.',
        },
    },
    doc => 'update the file system location of projects',
};

sub help_detail { $_[0]->__meta__->doc }

sub _before_execute {
    my $self = shift;
    $self->status_message('Update project(s) taxonomy...');
    $self->status_message('Taxon: %s', $self->taxon->__display_name__);
    $self->status_message('Chromosome: %s', $self->chromosome);
}

sub _execute_with_project {
    my ($self, $project) = @_;

    $self->status_message('Project: %s', $project->__display_name__);
    my $taxonomy = $project->taxonomy;
    $self->status_message('Current taxonomy %s', ($taxonomy ? $taxonomy->__display_name__ : 'NULL'));
    $taxonomy->delete if $taxonomy;
    my $new_taxonomy = RefImp::Project::Taxonomy->create(
        project => $project,
        taxon => $self->taxon,
        chromosome => $self->chromosome,
    );
    $self->status_message('New taxonomy %s', $project->taxonomy->__display_name__);
}

sub _after_execute {
    my $self = shift;
    $self->status_message('Update project(s) taxonomy...OK');
}

1;
