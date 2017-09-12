package Refimp::DataSource::TestDb;

use strict;
use warnings;

use UR;

class Refimp::DataSource::TestDb {
    is => 'UR::DataSource::SQLite',
    has_constant => {
        server => {
            value => Refimp::Config::get('ds_testdb_server'),
        },
    },
};

1;

