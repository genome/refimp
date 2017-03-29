#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 3;

my $pkg = 'RefImp::User';
use_ok($pkg) or die;

my $user;
subtest "basics" => sub{
    plan tests => 4;

    $user = $pkg->get(
        name => 'bobama'
    );
    ok($user, 'create user');
    ok($user->first_name, 'user has a first name');
    ok($user->last_name, 'user has a last name');
    ok($user->email, 'user has an email');

};

subtest 'name variants' => sub{
    plan tests => 2;

    is($user->first_initial, 'B', 'first_initial');
    is($user->last_name_uc, 'Obama', 'last_name_uc');
};

done_testing();
