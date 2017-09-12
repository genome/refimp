package Refimp::DataSource::Oltp;

use strict;
use warnings;

class Refimp::DataSource::Oltp {
    is => [qw/ UR::DataSource::Pg UR::DataSource::RDBMSRetriableOperations /],
    has_classwide_constant => [
        server  => { default_value => Refimp::Config::get('ds_oltp_server') },
        login   => { default_value => Refimp::Config::get('ds_oltp_login') },
        auth    => { default_value => Refimp::Config::get('ds_oltp_auth') },
        owner   => { default_value => Refimp::Config::get('ds_oltp_owner') },
    ],
};

sub table_and_column_names_are_upper_case { 1; }

1;

