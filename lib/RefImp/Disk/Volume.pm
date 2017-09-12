package Refimp::Disk::Volume;

use strict;
use warnings 'FATAL';

class Refimp::Disk::Volume {
    table_name => 'DISK_VOLUME',
    id_by => {
        dv_id => { is => 'Number' },
    },
    has => {
        mount_path => { is => 'Text' },
    },
    has_many_optional => {
        assignments => {
            is => 'Refimp::Disk::Assignment',
            reverse_id_by => 'volume',
        },
        groups => {
            is => 'Refimp::Disk::Group',
            via => 'assignments',
            to =>  'group',
        },
    },
    data_source => Refimp::Config::get('ds_oltp'),
    doc => 'disk volume',
};

sub __display_name__ { $_[0]->mount_path }

1;
