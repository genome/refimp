package RefImp::DataSource::TestDb;

use strict;
use warnings;

use UR;

class RefImp::DataSource::TestDb {
    is => 'UR::DataSource::SQLite',
    has_constant => {
        server => {
            value => RefImp::Config::get('ds_testdb_server'),
        },
    },
};

1;

