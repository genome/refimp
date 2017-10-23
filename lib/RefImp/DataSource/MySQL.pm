package RefImp::DataSource::MySQL;

use strict;
use warnings;

class RefImp::DataSource::MySQL {
    is => [qw/ UR::DataSource::RDBMSRetriableOperations UR::DataSource::MySQL /],
    has_classwide_constant => [
        server => { default_value => RefImp::Config::get('refimp_ds_server') },
        owner => { default_value => RefImp::Config::get('refimp_ds_owner') },
        database => { default_value => RefImp::Config::get('refimp_ds_database') },
        login => { default_value => RefImp::Config::get('refimp_ds_login') },
        auth => { default_value => RefImp::Config::get('refimp_ds_auth') },
    ],
};

1;

