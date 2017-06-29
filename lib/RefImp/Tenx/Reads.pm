package RefImp::Tenx::Reads;

use strict;
use warnings;

class RefImp::Tenx::Reads {
    table_name => 'tenx_reads',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        directory => { is => 'Text', doc => 'File system location of the read files', },
        sample_name => { is => 'Text', doc => 'Teh unique sample name.', },
    },
    has_optional => {
        targets_path => { is => 'Text', doc => 'The targets file, if exome.', },
    },
    has_calculated => {
        type => {
            calculate_from => [qw/ targets_path /],
            calculate => q| ( defined $targets_path ? 'targeted' : 'wgs' ) |,
        },
    },
    data_source => RefImp::Config::get('ds_mysql'),
};

1;
