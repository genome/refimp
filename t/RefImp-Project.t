#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Spec qw();
use File::Temp;
use Test::Exception;
use Test::More tests => 4;

my $project;
subtest "basics" => sub{
    plan tests => 5;

    use_ok('RefImp::Project') or die;

    $project = RefImp::Project->get(1);
    ok($project, 'got project');
    ok($project->name, 'project has a name');
    is($project->status('new'), 'new', 'status');
    is($project->clone_type, 'bac', 'clone_type');

};

subtest "directory" => sub{
    plan tests => 7;

    my $expected_directory = File::Spec->join( RefImp::Config::get('seqmgr'), $project->name);
    is($project->directory, $expected_directory, 'When no directory set, default to seqmgr directory');

    throws_ok(sub{ $project->directory('/doesnotexist'); }, qr/Directory to set does not exist/, 'cannot set non existing directory');

    $expected_directory = File::Temp::tempdir(CLEANUP => 1);
    $project->directory($expected_directory);
    is($project->directory, $expected_directory, 'set/get directory');

    for my $sub_dir_name ( RefImp::Project->sub_directory_names ) {
        ok(-d File::Spec->join($expected_directory, $sub_dir_name), "created $sub_dir_name");
    }

    $project->__directory(undef);

};

subtest 'subdir_for' => sub{
    plan tests => 5;

    throws_ok(sub{ $project->subdir_for; }, qr/but 2 were expected/, 'subdir_for failsd w/o subdir');
    my $expected_edit_dir = File::Spec->join($project->directory, 'edit_dir');

    for my $sub_dir_name ( $project->sub_directory_names ) {
        my $function_name = join('_', $sub_dir_name, 'directory');
        $function_name  =~ s/_dir_/_/;
        is($project->$function_name, File::Spec->join($project->directory, $sub_dir_name), "directory for $sub_dir_name");
    }

};

subtest "claimers" => sub{
    plan tests => 18;

    my $user = RefImp::User->get(1);
    for my $purpose ( RefImp::Project::User->valid_purposes ) {
        my $claimer = $project->add_project_user(user => $user, purpose => $purpose);
        ok($claimer, "created project $purpose");
        is($claimer->project, $project, "project user $purpose project");
        is($claimer->user, $user, "project user $[urpose user");
        is($claimer->purpose, $purpose, "project user $purpose purpose");
        ok($claimer->claimed_on, "project user $purpose claimed_on");

        my $method = $purpose.'s';
        my @users = $project->$method;
        is_deeply(\@users, [$user], "got $method");
    }

};

subtest 'notes file' => sub{
    plan tests => 3;

    my $notes_file_path = $project->notes_file_path;
    ok($notes_file_path, 'notes_file_path');
    ok(-s $notes_file_path, 'notes_file_path exists');
    ok($project->notes_file, 'notes_file');

};

subtest 'taxon' => sub{
    plan tests => 1;

    TestEnv::LimsRestApi::setup;
    ok($project->taxon, 'project has taxon');

};

done_testing();
