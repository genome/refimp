package RefImp::DataSource::MySQL;

use strict;
use warnings;

class RefImp::DataSource::MySQL {
    is => [qw/ UR::DataSource::RDBMSRetriableOperations UR::DataSource::MySQL /],
    has_classwide_constant => [
        server  => { default_value => RefImp::Config::get('ds_mysql_server') },
        login   => { default_value => RefImp::Config::get('ds_mysql_login') },
        auth    => { default_value => RefImp::Config::get('ds_mysql_auth') },
        owner   => { default_value => RefImp::Config::get('ds_mysql_owner') },
    ],
};

1;

