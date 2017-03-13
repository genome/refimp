package RefImp::Project::Taxonomy;

use strict;
use warnings 'FATAL';

class RefImp::Project::Taxonomy {
    table_name => 'projects_taxons',
    id_by => {
        project_id => { is => 'Text', },
        taxon_id => { is => 'Text', },
    },
    has => {
        project => { is => 'RefImp::Project', id_by => 'project_id', },
        taxon => { is => 'RefImp::Taxon', id_by => 'taxon_id', },
        common_name => { via => 'taxon', to => 'name', },
        species_name => {via => 'taxon', to => 'species_name', },
        chromosome => { is => 'Text', },
    },
    data_source => RefImp::Config::get('ds_mysql'),
};

1;

