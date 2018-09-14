package Tenx::Alignment;

use strict;
use warnings;

class Tenx::Alignment {
    table_name => 'tenx_alignments',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        directory => { is => 'Text', doc => 'File system location.', },
        reads => {
            is => 'Tenx::Reads',
            id_by => 'reads_id',
            doc => 'The reads that are aligned.',
        },
        reference => {
            is => 'Tenx::Reference',
            id_by => 'reference_id',
            doc => 'The reference sequence the reads are aligned to.',
        },
    },
    has_optional => {
        status => {
            is => 'Text',
            doc => 'The status of the alignment: running, succeeded, failed, etc.',
        },
    },
    data_source => Tenx::Config::get('tenx_ds'),
};

1;
