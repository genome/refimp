#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use File::Temp;
use File::Spec;
use Test::MockObject;
use Test::More tests => 2;

use Carp; $SIG{__DIE__} = sub{ Carp::confess(@_); };

my $pkg_name = 'RefImp::Project::Command::Makecon';
use_ok($pkg_name) or die;

my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $project = RefImp::Project->get(1);
TestEnv::setup_test_lims_rest_api(species_name => 'human', chromsome => 7);

subtest 'from analysis directory' => sub{
    plan tests => 2;

    my $output_file = File::Spec->join($tempdir, 'from_ace.con');
    my $makecon = $pkg_name->execute(
        project => $project,
        output_file => $output_file,
    );
    ok($makecon->result, 'execute');
    ok(-s $output_file, 'wrote output_file');

};

done_testing();
