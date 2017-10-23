package RefImp::Disk::Assignment;

use strict;
use warnings 'FATAL';

class RefImp::Disk::Assignment {
    table_name => 'DISK_VOLUME_GROUP',
    id_by => {
        dg_id => { is => 'Number', doc => 'Disk group ID', },
        dv_id => { is => 'Number', doc => 'Disk volume ID' },
    },
    has => {
        group => {
            is => 'RefImp::Disk::Group',
            id_by => 'dg_id',
        },
        volume => {
            is => 'RefImp::Disk::Volume',
            id_by => 'dv_id',
        },
    },
    data_source => RefImp::Config::get('refimp_ds_oltp'),
    doc => 'disk group volume bridge',
};

1;
