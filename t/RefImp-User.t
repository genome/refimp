#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;
use Test::More tests => 5;

my $pkg = 'RefImp::User';
use_ok($pkg) or die;

my $user;
subtest "basics" => sub{
    plan tests => 3;

    $user = $pkg->create(unix_login => 'bobama', first_name => 'barry', last_name => 'obama');
    ok($user, 'create user');
    ok($user->first_name, 'user has a first name');
    ok($user->last_name, 'user has a last name');

};

subtest 'name variants' => sub{
    plan tests => 2;

    is($user->first_initial, 'B', 'first_initial');
    is($user->last_name_uc, 'Obama', 'last_name_uc');
};

subtest 'user functions' => sub{
    plan tests => 2;

    my $function = RefImp::User::Function->create(gu_id => $user->id);
    ok($function, 'create function');
    is_deeply([$user->functions], [$function], 'user has functions');

};

subtest 'email' => sub{
    plan tests => 3;

    is($user->email_domain, 'wustl.edu', 'email domain');

    Sub::Install::reinstall_sub({
            code => sub{ undef },
            as => 'mail_for_unix_login',
            into => 'RefImp::Resources::LDAP',
        });
    is($user->email, 'bobama@'.$user->email_domain, 'email');

    my $ldap_mail = 'barack.obama@usa.gov';
    Sub::Install::reinstall_sub({
            code => sub{ $ldap_mail },
            as => 'mail_for_unix_login',
            into => 'RefImp::Resources::LDAP',
        });
    is($user->email, $ldap_mail, 'email from LDAP');

};

done_testing();
