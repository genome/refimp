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
        taxon => {
            is => 'RefImp::Taxon',
            id_by => 'taxon_id',
            doc => 'The assembly taxon.',
        },
    },
    has_optional => {
        directory => { is => 'Text', doc => 'File system location.', },
    },
    data_source => RefImp::Config::get('ds_mysql'),
};

sub __display_name__ { sprintf('%s (%s)', $_[0]->name, $_[0]->id) }

1;
