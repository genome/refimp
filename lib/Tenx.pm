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

use Tenx::Config;
if ( $ENV{TENX_CONFIG_FILE} ) {
    Tenx::Config::load_config_from_file( $ENV{TENX_CONFIG_FILE} );
}

1;
