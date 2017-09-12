package Refimp::Disk::Group;

use strict;
use warnings 'FATAL';

class Refimp::Disk::Group {
    table_name => 'DISK_GROUP',
    id_by => {
        dg_id => { is => 'Number' },
    },
    has => {
        disk_group_name => { is => 'Text' },
    },
    has_many_optional => {
        assignments => {
            is => 'Refimp::Disk::Assignment',
            reverse_id_by => 'group',
        },
        volumes => {
            is => 'Refimp::Disk::Volume',
            via => 'assignments',
            to =>  'volume',
        },
    },
    data_source => Refimp::Config::get('ds_oltp'),
    doc => "disk group",
};

1;
