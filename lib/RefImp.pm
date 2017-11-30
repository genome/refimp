package RefImp;

use warnings 'FATAL';
use strict;

our $VERSION = '0.010100';

use RefImp::Config;
use UR;

UR::Object::Type->define(
    class_name => 'RefImp',
    is => ['UR::Namespace'],
    english_name => 'reference improvement',
);

if ( $ENV{REFIMP_CONFIG_FILE} ) {
    RefImp::Config::load_config_from_file( $ENV{REFIMP_CONFIG_FILE} );
}

1;
