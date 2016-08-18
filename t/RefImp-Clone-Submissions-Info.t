#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use File::Spec;
use Test::More tests => 3;
use YAML;

my $pkg = 'RefImp::Clone::Submissions::Info';
use_ok($pkg) or die;

my $clone = RefImp::Test::Factory->setup_test_clone;
my $project = RefImp::Test::Factory->setup_test_project;
my $expected_hash = YAML::LoadFile( File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'expected.yml') );

subtest 'generate' => sub{
    plan tests => 1;

    my $hash = $pkg->generate($clone);
    is_deeply($hash, $expected_hash, 'hash matches');

};

subtest 'load' => sub{
    plan tests => 1;

    my $hash = $pkg->load( File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'expected.yml') );
    is_deeply($hash, $expected_hash, 'hash matches');

};

done_testing();
