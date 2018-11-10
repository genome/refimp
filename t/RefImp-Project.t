#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Spec qw();
use File::Temp;
use Test::Exception;
use Test::More tests => 8;

my $project;
subtest "basics" => sub{
    plan tests => 5;

    use_ok('RefImp::Project') or die;

    $project = RefImp::Project->get(1);
    ok($project, 'got project');
    ok($project->name, 'project has a name');
    is($project->status('new'), 'new', 'status');
    is($project->clone_type, 'bac', 'clone_type');
    $project->directory( File::Spec->join(RefImp::Config::get('test_data_path'), 'seqmgr', $project->name) );

};

subtest 'create_project_directory_structure' => sub{
    plan tests => 4;

    my $directory = $project->directory;
    my $new_directory = File::Temp::tempdir(CLEANUP => 1);
    $project->directory($new_directory);

    $project->create_project_directory_structure;
    for my $sub_dir_name ( RefImp::Project->sub_directory_names ) {
        ok(-d File::Spec->join($new_directory, $sub_dir_name), "created $sub_dir_name");
    }

    $project->directory($directory);

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
    plan tests => 15;

    my $user = RefImp::User->get(1);
    for my $purpose ( RefImp::Project::User->valid_purposes ) {
        my $claimer = $project->add_project_user(user => $user, purpose => $purpose);
        ok($claimer, "created project $purpose");
        is($claimer->project, $project, "project user $purpose project");
        is($claimer->user, $user, "project user $[urpose user");
        is($claimer->purpose, $purpose, "project user $purpose purpose");

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

subtest 'taxonomy' => sub{
    plan tests => 2;

    my $taxonomy = $project->taxonomy;
    ok($taxonomy, 'project has taxonomy');
    is($project->taxon, $taxonomy->taxon, 'project taxon');

};

subtest 'my_status' => sub{
    plan tests => 4;

    my $project_finisher = $project->project_finishers;
    ok($project_finisher, 'got project_finisher');

    ok(!$project_finisher->status, 'no status for project_finisher');
    ok(!$project->my_status, 'no my_status for project');

    my $my_status = 'Good to presubmit';
    $project_finisher->status($my_status);
    is($project->my_status, $my_status, 'got my_status');

};

subtest 'delete' => sub{
    plan tests => 3;

    my $taxonomy = $project->taxonomy;
    ok($project->delete, 'delete project');
    isa_ok($taxonomy, 'UR::DeletedRef', 'deleted taxonomy');
    ok(UR::Context->commit, 'commit');

};

done_testing();
