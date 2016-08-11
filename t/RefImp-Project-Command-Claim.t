#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use Test::More tests => 2;

my $pkg = 'RefImp::Project::Command::Claim';

my ($project, $user);
subtest "setup" => sub{
    plan tests => 1;

    use_ok($pkg) or die;

    $project = RefImp::Test::Factory->setup_test_project;
    $project->status('10X done');
    $user = RefImp::Test::Factory->setup_test_user;

};

subtest 'claim' => sub{
    plan tests => 4;

    my $claim = $pkg->execute(
        project => $project,
        as => 'finisher',
        unix_login => $user->unix_login,
    );
    ok($claim->result, 'execute');

    my $pf = RefImp::Project::Finisher->get(project => $project);
    ok($pf, 'added finisher to project');

    is($project->status, 'finish_start', 'set project status');
    my $psh = RefImp::Project::StatusHistory->get(
        project => $project,
        project_status => 'finish_start',
    );
    ok($psh, 'created project status history');

};

done_testing();
