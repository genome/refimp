package RefImp::Config;

use strict;
use warnings;

use File::Spec;
use YAML;

#FIXME
#my @directory_parts = File::Spec->splitdir( File::Spec->rel2abs( dirname(__FILE__) ) );
#splice @directory_parts, -2, 2;
#return File::Spec->join(@directory_parts, 'config.yml');
my %config = YAML::LoadFile();

sub get {
    my ($key) = @_;
    Carp::croak("No key to get config!") if not defined $key;
    return $config{$key} if exists $config{$key};
    Carp::croak("Invalid key to get config! $key");
}

sub set {
    my ($key, $value) = @_;
    Carp::croak("No key/value to set config!") if not defined $key;
    Carp::croak("No value to set config!") if not defined $value; # must be at least defined ('') for now...
    return $config{$key} = $value if exists $config{$key};
    Carp::croak("Invalid key to set config! $key");
}

1;

