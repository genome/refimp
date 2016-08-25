#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use File::Temp;
use File::Spec;
use Sub::Install;
use Test::More tests => 3;

my $pkg_name = 'RefImp::Project::Command::Makecon';
use_ok($pkg_name) or die;

my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $project = RefImp::Project->get(1);
$project->status('finish_start');
TestEnv::Clone::setup_test_lims_rest_api;

subtest 'from analysis directory' => sub{
    plan tests => 2;

    my $output_file = File::Spec->join($tempdir, 'from_analysis_dir.con');
    my $makecon = $pkg_name->execute(
        project => $project,
        output_file => $output_file,
    );
    ok($makecon->result, 'execute');
    ok(-s $output_file, 'wrote output_file');

};

subtest 'from recent ace' => sub{
    plan tests => 2;

    Sub::Install::reinstall_sub({
            code => sub{ undef },
            into => $pkg_name,
            as => '_get_sequence_from_most_recent_submission',
        });

    my $output_file = File::Spec->join($tempdir, 'from_ace.con');
    my $makecon = $pkg_name->execute(
        project => $project,
        output_file => $output_file,
    );
    ok($makecon->result, 'execute');
    ok(-s $output_file, 'wrote output_file');

};

done_testing();
