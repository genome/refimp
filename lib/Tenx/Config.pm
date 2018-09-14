package Tenx::Config;

use strict;
use warnings;

use YAML;

my $config;
sub is_loaded { defined $config }

my $config_loaded_from;
sub config_loaded_from { $config_loaded_from }

sub load_config_from_file {
    my $file = shift;
    die "No config file given load!" if not $file;
    die "Config file $file does not exist!" if not -e $file;
    $config = YAML::LoadFile($file);
    die "Failed to load $file!" if not $config;
    $config_loaded_from = $file;
}

sub get {
    my ($key) = @_;
    die "No key to get config!" if not defined $key;
    return $config->{$key} if exists $config->{$key};
    die "Invalid key to get config! $key";
}

sub set {
    my ($key, $value) = @_;
    die "No key to set config!" if not defined $key;
    die "No value to set config!" if not defined $value or $value eq ''; # must be at least defined ('') for now...
    $config->{$key} = $value;
}

sub unset {
    my ($key) = @_;
    die "No key to unset config!" if not defined $key;
    delete $config->{$key} if delete $config->{$key};
}

sub to_string {
    return '' if not $config;
    YAML::Dump $config;
}

1;

