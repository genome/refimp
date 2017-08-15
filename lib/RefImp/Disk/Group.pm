package RefImp::Disk::Group;

use strict;
use warnings 'FATAL';

class RefImp::Disk::Group {
    table_name => 'DISK_GROUP',
    id_by => {
        dg_id => { is => 'Number' },
    },
    has => {
        disk_group_name => { is => 'Text' },
    },
    has_many_optional => {
        assignments => {
            is => 'RefImp::Disk::Assignment',
            reverse_id_by => 'group',
        },
        volumes => {
            is => 'RefImp::Disk::Volume',
            via => 'assignments',
            to =>  'volume',
        },
    },
    data_source => RefImp::Config::get('ds_oltp'),
    doc => "disk group",
};

1;
