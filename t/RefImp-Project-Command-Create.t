#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;
use Test::Exception;
use Test::More tests => 4;

use_ok('RefImp::Project::Command::Create') or die;

subtest 'create project w/o clone' => sub{
    plan tests => 8;

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

    ok(UR::Context->commit, 'commit');

};

subtest 'create project w/ clone' => sub{
    plan tests => 8;

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
        sub{ $cmd = RefImp::Project::Command::Create->execute( name => $name,); },
        'execute project create',
    );
    ok($cmd->result, 'execute successful');
    ok(!$cmd->warning_message, 'warning about non existing clone');

    $project = RefImp::Project->get(name => $name);
    ok($project, 'project created');
    is($project, $cmd->project, 'project set on command object');

    ok(UR::Context->commit, 'commit');

};

subtest 'recreate project fails' => sub{
    plan tests => 2;

    my $name = "TEST_PROJECT2";
    my $project = RefImp::Project->get(name => $name);
    ok($project, 'project exists');

    my $cmd;
    throws_ok(
        sub{ $cmd = RefImp::Project::Command::Create->execute( name => $name); },
        qr/Project already exists/,
        'execute project create fails when project exists',
    );

};

done_testing();
