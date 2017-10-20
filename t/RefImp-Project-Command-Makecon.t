#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use File::Compare;
use File::Spec;
use File::Temp;
use Sub::Install;
use Test::More tests => 3;

my $pkg_name = 'RefImp::Project::Command::Makecon';
use_ok($pkg_name) or die;

my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $project = RefImp::Project->get(1);
$project->status('finish_start');
TestEnv::LimsRestApi::setup;

subtest 'from recent ace' => sub{
    plan tests => 3;

    my $output_file = File::Spec->join($tempdir, 'from_ace.con');
    my $makecon = $pkg_name->execute(
        project => $project,
        output_file => $output_file,
    );
    ok($makecon->result, 'execute');
    ok(-s $output_file, 'wrote output_file');

    my $expected_output_file = File::Spec->join(TestEnv::test_data_directory_for_package($pkg_name), 'HMPB-AAD13A05.from-ace.con');
    is(File::Compare::compare($output_file, $expected_output_file), 0, 'output file matches');

};

subtest 'from lastest submission' => sub{
    plan tests => 3;

    my $submission = RefImp::Project::Submission->create(
        project => $project,
        directory => File::Spec->join(RefImp::Config::get('analysis_directory'), 'human', lc($project->name), '20160501'),
    );
    my $output_file = File::Spec->join($tempdir, 'from_analysis_dir.con');
    my $makecon = $pkg_name->execute(
        project => $project,
        output_file => $output_file,
    );
    ok($makecon->result, 'execute');
    ok(-s $output_file, 'wrote output_file');

    my $expected_output_file = File::Spec->join(TestEnv::test_data_directory_for_package($pkg_name), 'HMPB-AAD13A05.from-submission.con');
    is(File::Compare::compare($output_file, $expected_output_file), 0, 'output file matches');

};


done_testing();
