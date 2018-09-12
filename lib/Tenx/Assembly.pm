package Tenx::Assembly;

use strict;
use warnings 'FATAL';

class Tenx::Assembly {
    table_name => 'tenx_assemblies',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        directory => { is => 'Text', doc => 'File system location.', },
        reads => {
            is => 'Tenx::Reads',
            id_by => 'reads_id',
            doc => 'The reads that are assembled.',
        },
    },
    has_optional => {
        status => {
            is => 'Text',
            doc => 'The status of the assembly: running, succeeded, failed, etc.',
        },
    },
    data_source => Tenx::Config::get('tenx_ds'),
};

1;
