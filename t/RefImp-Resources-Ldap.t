#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use Net::LDAP;
use Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 1;

my %bobama_attrs = (
    'unix_login' => 'bobama',
    'mail' => 'barack.obama@usa.gov',
);
my $bobama;
my @entries;
subtest 'setup' => sub{
    plan tests => 2;

    use_ok('RefImp::Resources::LDAP');

    Sub::Install::reinstall_sub({
            code => sub{ @entries },
            into => 'Net::LDAP',
            as => 'entries',
        });

    my $mesg = Test::MockObject->new;
    $mesg->set_false('code');

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

done_testing();
