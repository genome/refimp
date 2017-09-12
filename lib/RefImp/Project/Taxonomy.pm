package Refimp::Project::Taxonomy;

use strict;
use warnings 'FATAL';

class Refimp::Project::Taxonomy {
    table_name => 'projects_taxa',
    id_by => {
        project => { is => 'Refimp::Project', id_by => 'project_id', },
        taxon => { is => 'Refimp::Taxon', id_by => 'taxon_id', constraint_name => 'protax_taxa_fk', },
    },
    has => {
        common_name => { via => 'taxon', to => 'name', },
        species_name => {via => 'taxon', to => 'species_name', },
        chromosome => { is => 'Text', },
    },
    data_source => Refimp::Config::get('ds_mysql'),
};

sub __display_name__ {
    sprintf('%s chromosome %s', $_[0]->taxon->__display_name__, $_[0]->chromosome);
}

1;
