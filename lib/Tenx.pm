package Tenx;

use strict;
use warnings 'FATAL';

our $VERSION = '0.010100';

use UR;

UR::Object::Type->define(
    class_name => 'Tenx',
    is => ['UR::Namespace'],
    english_name => 'tenx genomics',
);

use RefImp;
if ( $ENV{REFIMP_CONFIG_FILE} ) {
    RefImp::Config::load_config_from_file( $ENV{REFIMP_CONFIG_FILE} );
}

1;
