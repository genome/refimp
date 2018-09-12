#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 6;

my %test = ( class => 'Tenx::Config' );
use_ok($test{class}) or die;

subtest 'load_config_from_file' =>  sub{
    plan tests => 4;

    my $test_directory = TenxTestEnv::test_data_directory_for_class($test{class});
    my $invalid_yml = File::Spec->join($test_directory, 'config.invalid.yml');
    throws_ok(sub{ Tenx::Config::load_config_from_file($invalid_yml); }, qr/YAML Error/, 'load_config fails w/ invalid yml');

    my $config_file = File::Spec->join($test_directory, 'config.yml');
    ok(Tenx::Config::load_config_from_file($config_file), 'load_config_file');

    ok(Tenx::Config::is_loaded(), 'config is loaded');
    is(Tenx::Config::config_loaded_from(), $config_file, 'config_file_loaded');

};

subtest 'get' => sub{
    plan tests => 3;

    throws_ok(sub{ Tenx::Config::get(); }, qr/No key to get config\!/, 'get without key');
    throws_ok(sub{ Tenx::Config::get('nada'); }, qr/Invalid key to get config\! nada/, 'get with invalid key');
    is(Tenx::Config::get('key'), 'value', 'get');

};

subtest 'set' => sub{
    plan tests => 6;

    throws_ok(sub{ Tenx::Config::set(); }, qr/No key to set config\!/, 'set with no params');
    throws_ok(sub{ Tenx::Config::set('key'); }, qr/No value to set config\!/, 'set without value');

    lives_ok(sub{ Tenx::Config::set('key', 'new+value'); }, 'set');
    is(Tenx::Config::get('key'), 'new+value', 'get the new value');

    lives_ok(sub{ Tenx::Config::set('nada', 'new+key!'); }, 'set with new key');
    is(Tenx::Config::get('nada'), 'new+key!', 'get the new key value');

};

subtest 'to_string' => sub{
    plan tests => 1;

    my $config = Tenx::Config::to_string();
    my $expected_config = join("\n", "---", "key: new+value", "nada: new+key!", "");
    is($config, $expected_config, 'got config');

};

subtest 'unset' => sub{
    plan tests => 3;

    throws_ok(sub{ Tenx::Config::unset(); }, qr/No key to unset config\!/, 'set with no params');
    lives_ok(sub{ Tenx::Config::unset('nada'); }, 'unset nada');
    throws_ok(sub{ Tenx::Config::get('nada'); }, qr/Invalid key to get config\! nada/, 'get with invalid key');

};

done_testing();
