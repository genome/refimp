#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Spec qw();
use File::Temp;
use Test::Exception;
use Test::More tests => 5;

my $project;
subtest "basics" => sub{
    plan tests => 4;

    use_ok('RefImp::Project') or die;

    $project = RefImp::Project->get(1);
    ok($project, 'got project');
    ok($project->name, 'project has a name');
    can_ok($project, 'directory');


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
    plan tests => 3;

    my $expected_directory = File::Spec->join( RefImp::Config::get('seqmgr'), $project->name);
    is($project->directory, $expected_directory, 'When no directory set, default to seqmgr directory');
    $expected_directory = File::Temp::tempdir(CLEANUP => 1);
    $project->directory($expected_directory);
    is($project->directory, $expected_directory, 'set/get directory');
    throws_ok(sub{ $project->directory('/doesnotexist'); }, qr/Directory to set does not exist/, 'cannot set non existing directory');
    $project->__directory(undef);

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

done_testing();
