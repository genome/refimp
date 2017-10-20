#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 6;

my %test = ( class => 'RefImp::Config' );
use_ok($test{class}) or die;

subtest 'load_config_from_file' =>  sub{
    plan tests => 4;

    my $test_directory = TestEnv::test_data_directory_for_package($test{class});
    my $invalid_yml = File::Spec->join($test_directory, 'config.invalid.yml');
    throws_ok(sub{ RefImp::Config::load_config_from_file($invalid_yml); }, qr/YAML Error/, 'load_config fails w/ invalid yml');

    my $config_file = File::Spec->join($test_directory, 'config.yml');
    ok(RefImp::Config::load_config_from_file($config_file), 'load_config_file');

    ok(RefImp::Config::is_loaded(), 'config is loaded');
    is(RefImp::Config::config_loaded_from(), $config_file, 'config_file_loaded');

};

subtest 'get' => sub{
    plan tests => 3;

    throws_ok(sub{ RefImp::Config::get(); }, qr/No key to get config\!/, 'get without key');
    throws_ok(sub{ RefImp::Config::get('nada'); }, qr/Invalid key to get config\! nada/, 'get with invalid key');
    is(RefImp::Config::get('key'), 'value', 'get');

};

subtest 'set' => sub{
    plan tests => 6;

    throws_ok(sub{ RefImp::Config::set(); }, qr/No key to set config\!/, 'set with no params');
    throws_ok(sub{ RefImp::Config::set('key'); }, qr/No value to set config\!/, 'set without value');

    lives_ok(sub{ RefImp::Config::set('key', 'new+value'); }, 'set');
    is(RefImp::Config::get('key'), 'new+value', 'get the new value');

    lives_ok(sub{ RefImp::Config::set('nada', 'new+key!'); }, 'set with new key');
    is(RefImp::Config::get('nada'), 'new+key!', 'get the new key value');

};

subtest 'to_string' => sub{
    plan tests => 1;

    my $config = RefImp::Config::to_string();
    my $expected_config = join("\n", "---", "key: new+value", "nada: new+key!", "");
    is($config, $expected_config, 'got config');

};

subtest 'unset' => sub{
    plan tests => 3;

    throws_ok(sub{ RefImp::Config::unset(); }, qr/No key to unset config\!/, 'set with no params');
    lives_ok(sub{ RefImp::Config::unset('nada'); }, 'unset nada');
    throws_ok(sub{ RefImp::Config::get('nada'); }, qr/Invalid key to get config\! nada/, 'get with invalid key');

};

done_testing();
