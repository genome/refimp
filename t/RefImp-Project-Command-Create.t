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
    plan tests => 7;

    my $name = "TEST_PROJECT1";
    my $project = RefImp::Project->get(name => $name);
    ok(!$project, 'project does not exist');

    my $cmd;
    lives_ok(
        sub{
            $cmd = RefImp::Project::Command::Create->execute(
                names => [$name],
                status => 'finish_start',
            );
        },
        'execute project create',
    );
    ok($cmd->result, 'execute successful');
    like($cmd->warning_message, qr/No matching/, 'warning about non existing clone');

    $project = RefImp::Project->get(name => $name);
    ok($project, 'project created');
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
        sub{ $cmd = RefImp::Project::Command::Create->execute(
                names => [$name],
                directory => $tmpdir,
            ); },
        'execute project create',
    );
    ok($cmd->result, 'execute successful');
    ok(!$cmd->warning_message, 'warning about non existing clone');

    $project = RefImp::Project->get(name => $name);
    ok($project, 'project created');
    ok(-d $project->directory, 'created and set directory');

    ok(UR::Context->commit, 'commit');

};

subtest 'from file existing updates' => sub{
    plan tests => 6;

    my $name = "TEST_PROJECT1";
    my $project = RefImp::Project->get(name => $name);
    ok($project, 'project exists');
    is($project->status, 'finish_start', 'status');

    my $file = File::Spec->join($tmpdir, 'project_names');
    my $fh = IO::File->new($file, 'w');
    $fh->print("$name\n");
    $fh->close;

    my $cmd;
    lives_ok(
        sub{ $cmd = RefImp::Project::Command::Create->execute(
                names => [$file],
                status => 'unknown',
            ); },
        'execute when project exists',
    );
    ok($cmd->result, 'execute successful');

    is($project->status, 'unknown', 'status updated');
    ok(UR::Context->commit, 'commit');

};

done_testing();
