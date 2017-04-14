package RefImp::Assembly;

use strict;
use warnings;

class RefImp::Assembly {
    table_name => 'assemblies',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        name => { is => 'Text', doc => 'Name of the project.', },
    },
    has_optional => {
        directory => { is => 'Text', doc => 'File system location.', },
        taxon => {
            is => 'RefImp::Taxon',
            id_by => 'taxon_id',
            doc => 'The assembly taxon.',
        },
    },
    data_source => RefImp::Config::get('ds_mysql'),
};

1;
