#!/usr/bin/env lims-perl

use strict;
use warnings;

use File::Spec;
use Test::Exception;
use Test::More tests => 5;

use TestEnv;

subtest 'resolve_repo_path' => sub{
    plan tests => 3;

    throws_ok(sub{ TestEnv::resolve_repo_path(); }, qr/No file given/, 'fails w/o file');
    throws_ok(sub{ TestEnv::resolve_repo_path('/blah'); }, qr/does not exist/, 'fails with invalid file');
    ok(TestEnv::current_repo_path, 'current_repo_path set');

};

subtest 'RefImp' => sub {
    plan tests => 2;

    my ($refimp_in_inc) = grep { /RefImp\.pm/ } keys %INC;
    ok($refimp_in_inc, 'RefImp is in INC');

    my $repo_path = TestEnv::resolve_repo_path(__FILE__);
    is($INC{$refimp_in_inc}, File::Spec->join($repo_path, 'lib', 'RefImp.pm'), 'RefImp path is correct');

};

subtest 'ENVs' => sub{
    plan tests => 2;

    ok($ENV{UR_DBI_NO_COMMIT}, 'no commit is on');
    ok($ENV{UR_USE_DUMMY_AUTOGENERATED_IDS}, 'use dummy ids is on');

};

subtest 'config' => sub{
    plan tests => 6;

    my $repo_path = TestEnv::current_repo_path();
    my %expected_configs = (
        analysis_directory => File::Spec->join($repo_path, 't', 'data', 'analysis'),
        ds_oltp => 'RefImp::DataSource::TestDb',
        ds_testdb_server => File::Spec->join($repo_path, 't', 'data', 'test.db'),
        environment => 'test',
        seqmgr => File::Spec->join($repo_path, 't', 'data', 'seqmgr'),
        test_data_path => File::Spec->join($repo_path, 't', 'data'),
    );
    for my $config_key ( sort keys %expected_configs ) {
        is(RefImp::Config::get($config_key), $expected_configs{$config_key}, $config_key);
    }

};

subtest 'lims rest api' => sub{
    plan tests => 1;

    my $lims = TestEnv::Clone::setup_test_lims_rest_api();
    ok($lims, 'setup test lims rest api');

};

done_testing();
