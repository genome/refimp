package RefImp::Tenx::Reference;

use strict;
use warnings;

class RefImp::Tenx::Reference {
    table_name => 'tenx_references',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        directory => { is => 'Text', doc => 'File system location.', },
        name => { is => 'Text', doc => 'Short name of the reference.', },
        taxon => {
            is => 'RefImp::Taxon',
            id_by => 'taxon_id',
            doc => 'The reference taxon.',
        },
    },
    data_source => RefImp::Config::get('ds_mysql'),
};

sub __display_name__ { sprintf('%s (%s)', $_[0]->name, $_[0]->directory) }

1;
