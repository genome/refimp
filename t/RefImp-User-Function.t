#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 3;

my $pkg = 'RefImp::User::Function';

my $func;
subtest "basics" => sub{
    plan tests => 5;

    use_ok($pkg) or die;

    $func = $pkg->get(33);
    ok($func, 'got user function');
    ok($func->gu_id, 'gu_id');
    ok($func->function_id, 'function_id');
    ok($func->status, 'status');

};

subtest "work function" => sub{
    plan tests => 4;

    use_ok('RefImp::User::WorkFunction') or die;
    my $wf = RefImp::User::WorkFunction->get(333);
    ok($wf, 'created work function');

    is($func->work_function, $wf, 'has work function');
    is($func->name, $wf->name, 'function name');

};

subtest "is active" => sub{
    plan tests => 2;

    ok($func->is_active, 'is_active is true for status active');
    $func->status('inactive');
    ok(!$func->is_active, 'is_active is not true for status inactive');
    $func->status('active');

};

done_testing();
