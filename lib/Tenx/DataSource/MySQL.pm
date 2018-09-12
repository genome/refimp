package Tenx::DataSource::MySQL;

use strict;
use warnings 'FATAL';

class Tenx::DataSource::MySQL {
    is => [qw/ UR::DataSource::RDBMSRetriableOperations UR::DataSource::MySQL /],
    has_classwide_constant => [
        server => { default_value => Tenx::Config::get('tenx_ds_server') },
        owner => { default_value => Tenx::Config::get('tenx_ds_owner') },
        database => { default_value => Tenx::Config::get('tenx_ds_database') },
        login => { default_value => Tenx::Config::get('tenx_ds_login') },
        auth => { default_value => Tenx::Config::get('tenx_ds_auth') },
    ],
};

1;
