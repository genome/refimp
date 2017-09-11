#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 5;

use_ok('Refimp::Config') or die;

subtest 'load_config' =>  sub{
    plan tests => 6;

    throws_ok(sub{ Refimp::Config::load_config(); }, qr/No file given/, 'load_config fails w/o file');
    throws_ok(sub{ Refimp::Config::load_config("/blah"); }, qr/does not exist/, 'load_config fails with non exisiting file');

    my $test_directory = TestEnv::test_data_directory_for_package("Refimp::Config");
    my $invalid_yml = File::Spec->join($test_directory, 'config.invalid.yml');
    throws_ok(sub{ Refimp::Config::load_config($invalid_yml); }, qr/YAML Error/, 'load_config fails w/ invalid yml');

    my $config_file = File::Spec->join($test_directory, 'config.yml');
    ok(Refimp::Config::load_config($config_file), 'load_config_file');

    ok(Refimp::Config::is_loaded(), 'config is loaded');
    is(Refimp::Config::config_file_loaded(), $config_file, 'config_file_loaded');

};

subtest 'get' => sub{
    plan tests => 3;

    throws_ok(sub{ Refimp::Config::get(); }, qr/No key to get config\!/, 'get without key');
    throws_ok(sub{ Refimp::Config::get('nada'); }, qr/Invalid key to get config\! nada/, 'get with invalid key');
    is(Refimp::Config::get('key'), 'value', 'get');

};

subtest 'set' => sub{
    plan tests => 6;

    throws_ok(sub{ Refimp::Config::set(); }, qr/No key\/value to set config\!/, 'set with no params');
    throws_ok(sub{ Refimp::Config::set('key'); }, qr/No value to set config\!/, 'set without value');

    lives_ok(sub{ Refimp::Config::set('key', 'new+value'); }, 'set');
    is(Refimp::Config::get('key'), 'new+value', 'get the new value');

    lives_ok(sub{ Refimp::Config::set('nada', 'new+key!'); }, 'set with new key');
    is(Refimp::Config::get('nada'), 'new+key!', 'get the new key value');

};

subtest 'to_string' => sub{
    plan tests => 1;

    my $config = Refimp::Config::to_string();
    my $expected_config = join("\n", "---", "key: new+value", "nada: new+key!", "");
    is($config, $expected_config, 'got config');

};

done_testing();
