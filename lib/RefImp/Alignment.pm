package RefImp::Alignment;

use strict;
use warnings 'FATAL';

class RefImp::Alignment {
    table_name => 'alignments',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        tech => { is => 'Text', doc => 'The technology that created the alignment. Ex: pacbio, tenx, phrap, etc.' },
        url => { is => 'Text', doc => 'File system location.', },
        reads => {
            is => 'RefImp::Reads',
            id_by => 'reads_id',
            doc => 'The reads that are aligned.',
        },
        refseq => {
            is => 'RefImp::Refseq',
            id_by => 'refseq_id',
            doc => 'The reference sequence the reads are aligned to.',
        },
    },
    has_optional => {
        status => {
            is => 'Text',
            doc => 'The status of the alignment: running, succeeded, failed, etc.',
        },
    },
    data_source => RefImp::Config::get('refimp_ds'),
};

1;
