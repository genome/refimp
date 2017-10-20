#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use File::Spec;
use File::Temp;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::Command::Update::Directory';

subtest "setup" => sub{
    plan tests => 1;

    use_ok($pkg) or die;

};

subtest 'update' => sub{
    plan tests => 7;

    my $project = RefImp::Project->get(1);
    ok($project, 'got project') or die;

    my $new_dir = File::Temp::tempdir(CLEANUP => 1);
    my $update = $pkg->execute(
        projects => [ $project, ],
        value => $new_dir,
    );
    ok($update->result, 'execute');
    my $expected_directory = File::Spec->join($new_dir, $project->name);
    is($project->directory, $expected_directory, 'set new directory');

    for my $sub_dir_name ( RefImp::Project->sub_directory_names ) {
        ok(-d File::Spec->join($expected_directory, $sub_dir_name), "created $sub_dir_name");
    }

};

done_testing();
