#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use Net::LDAP;
use Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 2;

my %bobama_attrs = (
    'unix_login' => 'bobama',
    'mail' => 'barack.obama@usa.gov',
);
my $bobama;
my @entries;
subtest 'setup' => sub{
    plan tests => 2;

    use_ok('RefImp::Resources::LDAP');

    my $mesg = Test::MockObject->new;
    $mesg->set_false('code');
    $mesg->mock('entries', sub{ @entries });

    for my $method (qw/ bind unbind /) {
        Sub::Install::reinstall_sub({
                code => sub{ $mesg },
                into => 'Net::LDAP',
                as => $method,
            });
    }

    my %methods_and_expected_params = (
        start_tls => { verify => 'none'},
        search => { base => "dc=gsc,dc=wustl,dc=edu", filter => "(&(objectClass=Person)(uid=$bobama_attrs{unix_login}))", },
    );
    for my $method ( keys %methods_and_expected_params ) {
        Sub::Install::reinstall_sub({
                code => sub{ 
                    my ($net_ldap, %p) = @_;
                    is_deeply(\%p, $methods_and_expected_params{$method}, "$method params match");
                    $mesg;
                },
                into => 'Net::LDAP',
                as => $method,
            });
    }

    $bobama = Test::MockObject->new;
    $bobama->mock('get_value', sub{ $bobama_attrs{$_[1]} });
    is($bobama->get_value('mail'), $bobama_attrs{mail}, 'bobama setup');

};

subtest 'ldap_user_for_unix_login' => sub{
    plan tests => 8; # 4 + param handling above

    throws_ok(
        sub{ RefImp::Resources::LDAP->ldap_user_for_unix_login; },
        qr/but 2 were expected/,
        'fails w/o unix_login',
    );
    my $ldap_user;
    lives_ok(
        sub{ $ldap_user = RefImp::Resources::LDAP->ldap_user_for_unix_login($bobama_attrs{unix_login}); },
        'lives when no entries are found',
    );

    @entries = $bobama;
    lives_ok(
        sub{ $ldap_user = RefImp::Resources::LDAP->ldap_user_for_unix_login($bobama_attrs{unix_login}); },
        'lives when no entries are found',
    );
    is($ldap_user, $bobama, 'got correct ldap user');

};

done_testing();
