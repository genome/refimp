#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::User';
my ($project, $user);

subtest 'setup' => sub{
    plan tests => 3;

    use_ok($pkg) or die;

    $project = RefImp::Project->get(1);
    ok($project, 'got project');
    $user = RefImp::User->get(1);
    ok($user, 'got user');

};

subtest 'create' => sub{
    plan tests => 6;

    my @valid_purposes = $pkg->valid_purposes;
    is(@valid_purposes, 3, 'valid_purposes');

    my $claimer = $pkg->create(
        project => $project,
        user => $user,
        purpose => $valid_purposes[0],
    );
    ok($claimer, 'create project user for '.$claimer->purpose);
    is($claimer->project, $project, 'project');
    is($claimer->user, $user, 'user');
    is($claimer->purpose, $valid_purposes[0], 'correct purpose');
    ok($claimer->claimed_on, 'set claimed_on');

};

done_testing();
