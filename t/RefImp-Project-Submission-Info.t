#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Spec;
use Test::More tests => 3;
use YAML;

my $pkg = 'RefImp::Project::Submission::Info';
use_ok($pkg) or die;

my $expected_hash = YAML::LoadFile( File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'expected.yml') );
TestEnv::LimsRestApi::setup;

subtest 'generate' => sub{
    plan tests => 1;

    my $project = RefImp::Project->get(1);
    $project->directory( File::Spec->join(RefImp::Config::get('test_data_path'), 'seqmgr', $project->name) );
    $project->create_project_directory_structure;

    my $hash = $pkg->generate($project);
    is_deeply($hash, $expected_hash, 'hash matches');

};

subtest 'load' => sub{
    plan tests => 1;

    my $hash = $pkg->load( File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'expected.yml') );
    is_deeply($hash, $expected_hash, 'hash matches');

};

done_testing();
