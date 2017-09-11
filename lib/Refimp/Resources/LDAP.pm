package Refimp::Resources::LDAP;

use strict;
use warnings 'FATAL';

use Net::LDAP;
use Params::Validate qw/ :types validate_pos /;

class Refimp::Resources::LDAP {};

sub ldap_user_for_unix_login {
    my ($class, $unix_login) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    my $ldap = Net::LDAP->new(Refimp::Config::get('net_ldap_url'), version => 3);
    my $mesg = $ldap->start_tls(verify => 'none');
    $mesg->code && die $mesg->error;

    $mesg = $ldap->bind;
    $mesg->code && die $mesg->error;

    $mesg = $ldap->search(
        base => "dc=gsc,dc=wustl,dc=edu",
        filter => "(&(objectClass=Person)(uid=$unix_login))",
    );
    $mesg->code && die $mesg->error;

    my @ldap_users = $mesg->entries;
    if ( not @ldap_users ) {
        $class->warning_message('No LDAP entry fround for %s!', $unix_login);
        return;
    }

    $mesg = $ldap->unbind;   # take down session
    $mesg->code && die $mesg->error;

    $ldap_users[0];
}

sub mail_for_unix_login {
    my ($class, $unix_login) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});
    my $ldap_user = $class->ldap_user_for_unix_login($unix_login);
    return if not $ldap_user;
    $ldap_user->get_value('mail');
}

1;

