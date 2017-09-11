package Refimp::Project::Command::Update::Taxonomy;

use strict;
use warnings;

use Refimp::Util::Tablizer;

class Refimp::Project::Command::Update::Taxonomy { 
    is => 'Refimp::Project::Command::BaseWithMany',
    has_input => {
        taxon => {
            is => 'Refimp::Taxon',
            doc => 'Taxon for the project.',
        },
        chromosome => {
            is => 'Text',
            default_value => 'unknown',
            doc => 'Chromosome for the project.',
        },
    },
    has_transient_optional => {
        old_values => { is => 'ARRAY', default_value => [], },
    },
    doc => 'update the taxonomy of projects',
};

sub help_detail { $_[0]->__meta__->doc }

sub _execute_with_project {
    my ($self, $project) = @_;

    my $taxonomy = $project->taxonomy;
    my $old_taxonomy = ($taxonomy ? $taxonomy->__display_name__ : 'NULL');
    push @{$self->old_values}, $old_taxonomy;
    $taxonomy->delete if $taxonomy;

    Refimp::Project::Taxonomy->create(
        project => $project,
        taxon => $self->taxon,
        chromosome => $self->chromosome,
    );
}

sub _after_execute {
    my $self = shift;

    my @rows = (
        [qw/ ID NAME TAXONOMY OLD_TAXONOMY /],
        [qw/ -- ---- -------- ------------ /],
    );

    my $old_values = $self->old_values;
    my $i = 0;
    for my $project ( $self->projects ) {
        push @rows, [ map({ $project->$_ } (qw/ id name /)), $project->taxonomy->__display_name__, $old_values->[$i] ];
        $i++;
    }

    print Refimp::Util::Tablizer->format(\@rows);
}

1;
