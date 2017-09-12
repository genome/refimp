#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;

use File::Spec;
use File::Temp;
use Test::More tests => 2;
use YAML 'LoadFile';

my $pkg = 'Refimp::Project::Submission::Asn';
use_ok($pkg) or die;

subtest 'create' => sub{
    plan tests => 3;

    my $data_dir = TestEnv::test_data_directory_for_package($pkg);
    TestEnv::LimsRestApi::setup;

    my $project = Refimp::Project->get(1);
    my $project_name = $project->name;
    my $submit_info = LoadFile( File::Spec->join($data_dir, 'HMPB-AAD13A05.yml') );

    my $working_directory = File::Temp::tempdir(CLEANUP => 1);
    symlink File::Spec->join($data_dir, "$project_name.seq"), File::Spec->join($working_directory, "$project_name.seq");

    Refimp::User->create(name => 'bobama', first_name => 'barack', last_name => 'obama');
    Refimp::User->create(name => 'jbiden', first_name => 'joe', last_name => 'biden');

    my $asn = $pkg->create(
        project => $project,
        submit_info => $submit_info,
        working_directory => $working_directory,
    );
    ok($asn, 'create');
    $asn->generate;
    ok(-s $asn->template_path, 'template_path created'); # date is on file, need way to compare...
    ok(-s $asn->asn_path, 'asn_path created'); # date is on file, need way to compare...

};

done_testing();
