package RefImp::Tenx::Alignment;

use strict;
use warnings;

class RefImp::Tenx::Alignment {
    table_name => 'tenx_alignments',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        directory => { is => 'Text', doc => 'File system location.', },
        reads => {
            is => 'RefImp::Tenx::Reads',
            id_by => 'reads_id',
            doc => 'The reads that are aligned',
        },
        reference => {
            is => 'RefImp::Tenx::Reference',
            id_by => 'reference_id',
            doc => 'The reference sequence the reads are aligned to',
        },
    },
    has_optional => {
        status => {
            is => 'Text',
            doc => 'The status of the alignment: running, succeeded, failed, etc.',
        },
    },
    data_source => RefImp::Config::get('ds_mysql'),
};

1;
