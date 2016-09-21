#!/usr/bin/env perl5.12.1

use strict;
use warnings;

use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 4;

use_ok('RefImp::Config') or die;

subtest 'load_config' =>  sub{
    plan tests => 6;

    throws_ok(sub{ RefImp::Config::load_config(); }, qr/No file given/, 'load_config fails w/o file');
    throws_ok(sub{ RefImp::Config::load_config("/blah"); }, qr/does not exist/, 'load_config fails with non exisiting file');

    my $test_directory = TestEnv::test_data_directory_for_package("RefImp::Config");
    my $invalid_yml = File::Spec->join($test_directory, 'config.invalid.yml');
    throws_ok(sub{ RefImp::Config::load_config($invalid_yml); }, qr/YAML Error/, 'load_config fails w/ invalid yml');

    my $config_file = File::Spec->join($test_directory, 'config.yml');
    ok(RefImp::Config::load_config($config_file), 'load_config_file');

    ok(RefImp::Config::is_loaded(), 'config is loaded');
    is(RefImp::Config::config_file_loaded(), $config_file, 'config_file_loaded');

};

subtest 'get' => sub{
    plan tests => 3;

    throws_ok(sub{ RefImp::Config::get(); }, qr/No key to get config\!/, 'get without key');
    throws_ok(sub{ RefImp::Config::get('nada'); }, qr/Invalid key to get config\! nada/, 'get with invalid key');
    is(RefImp::Config::get('key'), 'value', 'get');

};

subtest 'set' => sub{
    plan tests => 6;

    throws_ok(sub{ RefImp::Config::set(); }, qr/No key\/value to set config\!/, 'set with no params');
    throws_ok(sub{ RefImp::Config::set('key'); }, qr/No value to set config\!/, 'set without value');

    lives_ok(sub{ RefImp::Config::set('key', 'new+value'); }, 'set');
    is(RefImp::Config::get('key'), 'new+value', 'get the new value');

    lives_ok(sub{ RefImp::Config::set('nada', 'new+key!'); }, 'set with new key');
    is(RefImp::Config::get('nada'), 'new+key!', 'get the new key value');

};

done_testing();
