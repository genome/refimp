#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use Test::More tests => 2;

my $pkg = 'RefImp::Project::Command::Claim';

my ($project, $user);
subtest "setup" => sub{
    plan tests => 1;

    use_ok($pkg) or die;

    $project = RefImp::Project->get(1);
    $project->status('10X done');
    $user = RefImp::User->get(1);

};

subtest 'claim' => sub{
    plan tests => 5;

    my $claim = $pkg->execute(
        project => $project,
        as => 'finisher',
        user => $user,
    );
    ok($claim->result, 'execute');

    my $claimer = RefImp::Project::User->get(project => $project);
    ok($claimer, 'added user to project');
    is($claimer->user, $user, 'project user => user');
    is($claimer->purpose, 'finisher', 'project user => purpose');
    is($project->status, 'finish_start', 'set project status');

};

done_testing();
