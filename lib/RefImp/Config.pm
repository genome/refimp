package RefImp::Config;

use strict;
use warnings;

use File::Spec;
use YAML;

my $config;
sub is_loaded { defined $config }
my $config_file_loaded;
sub config_file_loaded { $config_file_loaded }

sub load_refimp_config_file {
    return if is_loaded(); # only load the refimp config once
    return if ! defined $ENV{REFIMP_CONFIG_FILE}; # only load if env set
    load_config( $ENV{REFIMP_CONFIG_FILE} );
}

sub load_config {
    my $file = shift;
    Carp::croak("No file given to load_config!") if not $file;
    Carp::croak("File given to load_config does not exist!") if not -e $file;
    $config = YAML::LoadFile($file);
    $config_file_loaded = $file;
}

sub get {
    my ($key) = @_;
    Carp::croak("No key to get config!") if not defined $key;
    return $config->{$key} if exists $config->{$key};
    Carp::croak("Invalid key to get config! $key");
}

sub set {
    my ($key, $value) = @_;
    Carp::croak("No key/value to set config!") if not defined $key;
    Carp::croak("No value to set config!") if not defined $value; # must be at least defined ('') for now...
    return $config->{$key} = $value if exists $config->{$key};
    Carp::croak("Invalid key to set config! $key");
}

1;

