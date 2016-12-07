#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Temp;
use Test::Exception;
use Test::More tests => 4;

use_ok('RefImp::Project::Command::Create') or die;
my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

subtest 'create project w/o clone' => sub{
    plan tests => 10;

    my $name = "TEST_PROJECT1";
    my $project = RefImp::Project->get(name => $name);
    ok(!$project, 'project does not exist');

    my $cmd;
    lives_ok(
        sub{
            $cmd = RefImp::Project::Command::Create->execute(
                name => $name,
                status => 'finish_start',
            );
        },
        'execute project create',
    );
    ok($cmd->result, 'execute successful');
    like($cmd->warning_message, qr/No matching/, 'warning about non existing clone');

    $project = RefImp::Project->get(name => $name);
    ok($project, 'project created');
    is($project, $cmd->project, 'project set on command object');
    is($project->status, 'finish_start', 'status set');

    my @sh = $project->status_histories;
    is(@sh, 1, 'added project status history');
    is($sh[0]->project_status, $project->status, 'project status matches');

    ok(UR::Context->commit, 'commit');

};

subtest 'create project w/ clone' => sub{
    plan tests => 9;

    my $name = "TEST_PROJECT2";
    my $project = RefImp::Project->get(name => $name);
    ok(!$project, 'project does not exist');

    my $clone = RefImp::Clone->create(
        name => $name,
        status => 'active',
        type => 'bac',
    );
    ok($clone, "create clone for $name");

    my $cmd;
    lives_ok(
        sub{ $cmd = RefImp::Project::Command::Create->execute(
                name => $name,
                directory => $tmpdir,
            ); },
        'execute project create',
    );
    ok($cmd->result, 'execute successful');
    ok(!$cmd->warning_message, 'warning about non existing clone');

    $project = RefImp::Project->get(name => $name);
    ok($project, 'project created');
    is($project, $cmd->project, 'project set on command object');
    ok(-d $project->directory, 'created and set directory');

    ok(UR::Context->commit, 'commit');

};

subtest 'recreate updates existing' => sub{
    plan tests => 5;

    my $name = "TEST_PROJECT1";
    my $project = RefImp::Project->get(name => $name);
    ok($project, 'project exists');

    my $cmd;
    lives_ok(
        sub{ $cmd = RefImp::Project::Command::Create->execute(
                name => $name,
                status => 'unknown',
            ); },
        'execute when project exists',
    );
    ok($cmd->result, 'execute successful');

    is($project->status, 'unknown', 'status set');
    ok(UR::Context->commit, 'commit');

};

done_testing();
