#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Temp;
use Path::Class;
use Test::More tests => 2;
use YAML 'LoadFile';

my $pkg = 'RefImp::Project::Submission::Asn';
use_ok($pkg) or die;

subtest 'create' => sub{
    plan tests => 5;

    my $data_dir = TestEnv::test_data_directory_for_class($pkg);
    TestEnv::LimsRestApi::setup;

    my $project = RefImp::Project->get(1);
    my $project_name = $project->name;
    my $submit_info = LoadFile( $data_dir->file('HMPB-AAD13A05.yml') );

    my $working_directory = dir( File::Temp::tempdir(CLEANUP => 1) );
    symlink $data_dir->file("$project_name.seq"), $working_directory->file( "$project_name.seq");

    RefImp::User->create(name => 'bobama', first_name => 'barack', last_name => 'obama');
    RefImp::User->create(name => 'jbiden', first_name => 'joe', last_name => 'biden');

    my $asn = $pkg->create(
        project => $project,
        submit_info => $submit_info,
        working_directory => $working_directory,
    );
    ok($asn, 'create');
    $asn->generate;
    ok(-s $asn->template_path, 'template_path created'); # date is on file, need way to compare...
    ok(-s $asn->asn_path, 'asn_path created'); # date is on file, need way to compare...
    is($asn->fsa_path, $working_directory->file($project_name.'.fsa'), 'fsa_path correct');
    ok(-s $asn->fsa_path, 'fsa_path created');

};

done_testing();
