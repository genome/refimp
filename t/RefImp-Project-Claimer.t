#!/usr/bin/env perl5.12.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my $base_pkg = 'RefImp::Project::Claimer';
my ($project, $user);

subtest 'setup' => sub{
    plan tests => 3;

    use_ok($base_pkg) or die;

    $project = RefImp::Project->get(1);
    ok($project, 'got project');
    $user = RefImp::User->get(1);
    ok($user, 'got user');

};

subtest "claimer function and types" => sub{
    plan tests => 4;

    my @valid_claim_types = $base_pkg->valid_claim_types;
    ok(@valid_claim_types, 'valid_claim_types');
    my $claimer_type = 'prefinisher';
    my $function_name = $base_pkg->function_for_claim_type($claimer_type);
    ok($function_name, 'function_for_claim_type '.$claimer_type);

    throws_ok(sub{ $base_pkg->claimer_function_for_user; }, qr/but 2 were expected/, 'claimer_function_for_user fails w/o user');
    my $pkg = $base_pkg->class_for_claimer_type($claimer_type);
    my ($expected_function) = grep { $_->name eq $function_name } $user->functions(status => 'inactive');
    is(
        $pkg->claimer_function_for_user($user),
        $expected_function,
        'claimer_function_for_user',
    );

};

subtest 'create_for_project_and_user' => sub{
    plan tests => 21;

    my @functions = $user->functions;
    for my $type ( $base_pkg->valid_claim_types ) {
        my $pkg = $base_pkg->class_for_claimer_type($type);
        use_ok($pkg) or die;

        my $claimer = $pkg->create_for_project_and_user(
            project => $project,
            user => $user,
        );
        ok($claimer, 'create project '.$pkg->claimer_type);
        is($claimer->claimer_type, $type, 'correct claimer_type');
        is($claimer->project, $project, 'project');

        my $function_name = $base_pkg->function_for_claim_type($type);
        my ($expected_function) = grep { $_->name eq $function_name } @functions;
        is($claimer->ei_id, $expected_function->id, 'claimer ei_id matches user funciton id');
        is($claimer->user_funtion, $expected_function, 'got user_function');
        is($claimer->user, $user, 'got user');
    }

};

done_testing();
