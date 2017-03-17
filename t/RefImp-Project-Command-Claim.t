#!/usr/bin/env perl5.10.1

use strict;
use warnings;

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
        unix_login => $user->name,
        project_status => 'finish_start',
    );
    ok($claim->result, 'execute');

    my $claimer = RefImp::Project::User->get(project => $project);
    ok($claimer, 'added user to project');
    is($claimer->user, $user, 'project user => user');
    is($claimer->purpose, 'finisher', 'project user => purpose');

    is($project->status, 'finish_start', 'set project status');

};

done_testing();
