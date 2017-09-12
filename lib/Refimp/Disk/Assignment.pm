package Refimp::Disk::Assignment;

use strict;
use warnings 'FATAL';

class Refimp::Disk::Assignment {
    table_name => 'DISK_VOLUME_GROUP',
    id_by => {
        dg_id => { is => 'Number', doc => 'Disk group ID', },
        dv_id => { is => 'Number', doc => 'Disk volume ID' },
    },
    has => {
        group => {
            is => 'Refimp::Disk::Group',
            id_by => 'dg_id',
        },
        volume => {
            is => 'Refimp::Disk::Volume',
            id_by => 'dv_id',
        },
    },
    data_source => Refimp::Config::get('ds_oltp'),
    doc => 'disk group volume bridge',
};

1;
