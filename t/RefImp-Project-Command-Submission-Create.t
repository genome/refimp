#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 1;


subtest 'create' => sub{
    plan tests => 10;

    my $pkg = 'RefImp::Project::Command::Submission::Create';
    use_ok($pkg) or die;

    my $project = RefImp::Project->get(1);
    ok($project, 'got project');

    my @submissions = $project->submissions;
    ok(!@submissions, 'project doe not have submissions');

    my $cmd;
    lives_ok(
        sub{ $cmd = $pkg->execute(
                project => $project,
                directory => '/tmp',
                phase => 3,
            ); },
        'execute taxon create',
    );
    ok($cmd->result, 'execute successful');

    @submissions = $project->submissions;
    is(@submissions, 1, 'created submission');
    is($submissions[0]->project, $project, 'set submission project');
    is($submissions[0]->directory, '/tmp', 'set submission directory');
    is($submissions[0]->phase, 3, 'set submission phase');

    ok(UR::Context->commit, 'commit');

};

done_testing();
