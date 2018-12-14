#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Compare 'compare';
use File::Temp;
use Path::Class;
use Test::More tests => 2;
use YAML 'LoadFile';

my $pkg = 'RefImp::Project::Submission::Asn';
use_ok($pkg) or die;

subtest 'create' => sub{
    plan tests => 8;

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

    my $fsa_bn = join('.', $project_name, 'fsa');
    is($asn->fsa_path, $working_directory->file($fsa_bn), 'fsa_path name');
    ok(-s $asn->fsa_path, 'fsa_path created');

    my $cmt_bn = join('.', $project_name, 'cmt');
    is($asn->cmt_path, $working_directory->file($cmt_bn), 'cmt_path name');
    ok(-s $asn->cmt_path, 'cmt_path created');
    is(compare($asn->cmt_path->stringify, $data_dir->file($cmt_bn)->stringify), 0, 'cmt_path as expected');

};

done_testing();
