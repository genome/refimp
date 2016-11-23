#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Spec qw();
use File::Temp;
use Test::Exception;
use Test::More tests => 9;

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

subtest "status" => sub{
    plan tests => 3;

    my @psh = $project->status_histories;
    ok(!@psh, 'no project status histories');
    is($project->status('finish_start'), 'finish_start', 'set status');
    @psh = $project->status_histories;
    is(@psh, 1, 'added psh');

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
    plan tests => 7;

    use_ok('RefImp::Project::Claimer') or die;

    for my $type ( RefImp::Project::Claimer::valid_claim_types() ) {
        my $add_method = 'add_claimed_as_'.$type;
        my $claimer = $project->$add_method(ei_id => -11);
        ok($claimer, "created project $type");
        my $claimed_as_method = 'claimed_as_'.$type;
        is($project->$claimed_as_method, $claimer, "added $type to project");
    }

};

subtest 'notes file' => sub{
    plan tests => 3;

    my $notes_file_path = $project->notes_file_path;
    ok($notes_file_path, 'notes_file_path');
    ok(-s $notes_file_path, 'notes_file_path exists');
    ok($project->notes_file, 'notes_file');

};

subtest 'clone' => sub{
    plan tests => 2;

    my $clone = RefImp::Clone->get(name => $project->name);
    ok($clone, 'got clone');
    is($project->clone, $clone, 'got project via clone');

};

subtest 'taxon' => sub{
    plan tests => 1;

    TestEnv::LimsRestApi::setup;
    ok($project->taxon, 'project has taxon');

};

subtest 'unknown taxon w/o clone' => sub{
    plan tests => 3;

    my $project = RefImp::Project->create(name => 'Testy McTesterson');
    ok($project, 'create project');
    ok(!$project->clone, 'project does not have a clone');
    is($project->taxon->species_name, 'unknown', 'got unkown taxon for project w/o clone');

};

done_testing();
