package Tenx::DataSource::SQLite;

use strict;
use warnings 'FATAL';

use UR;

class Tenx::DataSource::SQLite {
    is => 'UR::DataSource::SQLite',
    has_constant => {
        server => {
            value => Tenx::Config::get('tenx_ds_sqlite_server'),
        },
    },
};

1;

