#!/usr/bin/env lims-perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
};

use strict;
use warnings;

use above 'RefImp';

use File::Temp;
use File::Spec;
use RefImp::Test::Factory;
use Test::MockObject;
use Test::More tests => 2;

my $pkg_name = 'RefImp::Project::Command::Makecon';
use_ok($pkg_name) or die;

my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $clone = RefImp::Test::Factory->setup_test_clone;
my $project = RefImp::Test::Factory->setup_test_project;

subtest 'from analysis directory' => sub{
    plan tests => 2;

    RefImp::Test->set_analysis_directory_test_data_directory;
    my $output_file = File::Spec->join($tempdir, 'from_ace.con');
    my $makecon = $pkg_name->execute(
        project => $project,
        output_file => $output_file,
    );
    ok($makecon->result, 'execute');
    ok(-s $output_file, 'wrote output_file');

};

done_testing();
