#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;
use Test::Exception;
use Test::More tests => 4;

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

subtest 'parse_name' => sub{
    plan tests => 3;

    throws_ok(sub{ $pkg->parse_name; }, qr/but 2 were expected/, 'fails w/o name');
    throws_ok(sub{ $pkg->parse_name('Prince'); }, qr/Expected a last name in/, 'fails w/o last name');

    my $name = 'George Herbert Walker Bush';
    my $parsed_name = $pkg->parse_name($name);
    is_deeply($parsed_name, { first => 'George', last => 'Bush', initials => 'G.H.W.', }, $name);

};

done_testing();
