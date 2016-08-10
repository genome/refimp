package RefImp::DataSource::Oltp;

use strict;
use warnings;
use RefImp;

class RefImp::DataSource::Oltp {
    is => [qw/ UR::DataSource::RDBMSRetriableOperations UR::DataSource::Oracle /],
    has_classwide_constant => [
        server  => { default_value => RefImp::Config::get('ds_oltp_server') },
        login   => { default_value => RefImp::Config::get('ds_oltp_login') },
        auth    => { default_value => RefImp::Config::get('ds_oltp_auth') },
        owner   => { default_value => RefImp::Config::get('ds_oltp_owner') },
    ],
};

sub table_and_column_names_are_upper_case { 1; }

1;

