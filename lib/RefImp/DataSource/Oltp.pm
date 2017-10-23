package RefImp::DataSource::Oltp;

use strict;
use warnings;

class RefImp::DataSource::Oltp {
    is => [qw/ UR::DataSource::Pg UR::DataSource::RDBMSRetriableOperations /],
    has_classwide_constant => [
        server  => { default_value => RefImp::Config::get('refimp_ds_oltp_server') },
        login   => { default_value => RefImp::Config::get('refimp_ds_oltp_login') },
        auth    => { default_value => RefImp::Config::get('refimp_ds_oltp_auth') },
        owner   => { default_value => RefImp::Config::get('refimp_ds_oltp_owner') },
    ],
};

sub table_and_column_names_are_upper_case { 1; }

1;

