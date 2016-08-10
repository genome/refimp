#!/usr/bin/env lims-perl

BEGIN {
    $ENV{REFIMP_CONFIG_FILE} = undef;
}

use strict;
use warnings;

use above 'RefImp';

use File::Spec;
use RefImp::Test;
use Test::Exception;
use Test::More tests => 4;

use_ok('RefImp::Config') or die;

subtest 'load_config' =>  sub{
    plan tests => 7;

    ok(!RefImp::Config::is_loaded(), 'config is not loaded');

    throws_ok(sub{ RefImp::Config::load_config(); }, qr/No file given/, 'load_config fails w/o file');
    throws_ok(sub{ RefImp::Config::load_config("/blah"); }, qr/does not exist/, 'load_config fails with non exisiting file');

    my $test_directory = RefImp::Test->test_data_directory_for_package("RefImp::Config");
    my $invalid_yml = File::Spec->join($test_directory, 'config.invalid.yml');
    throws_ok(sub{ RefImp::Config::load_config($invalid_yml); }, qr/YAML Error/, 'load_config fails w/ invalid yml');

    $ENV{REFIMP_CONFIG_FILE} = File::Spec->join($test_directory, 'config.yml');
    ok(RefImp::Config::load_refimp_config_file(), 'load_refimp_config_file');

    ok(RefImp::Config::is_loaded(), 'config is loaded');
    is(RefImp::Config::config_file_loaded(), $ENV{REFIMP_CONFIG_FILE}, 'config_file_loaded');

};

subtest 'get' => sub{
    plan tests => 3;

    throws_ok(sub{ RefImp::Config::get(); }, qr/No key to get config\!/, 'get without key');
    throws_ok(sub{ RefImp::Config::get('nada'); }, qr/Invalid key to get config\! nada/, 'get with invalid key');
    is(RefImp::Config::get('key'), 'value', 'get');

};

subtest 'set' => sub{
    plan tests => 5;

    throws_ok(sub{ RefImp::Config::set(); }, qr/No key\/value to set config\!/, 'set with no params');
    throws_ok(sub{ RefImp::Config::set('key'); }, qr/No value to set config\!/, 'set without value');
    throws_ok(sub{ RefImp::Config::set('nada', 'new+value'); }, qr/Invalid key to set config\! nada/, 'set with invalid key');
    lives_ok(sub{ RefImp::Config::set('key', 'new+value'); }, 'set');
    is(RefImp::Config::get('key'), 'new+value', 'get the new value');

};

done_testing();
