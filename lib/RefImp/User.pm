package RefImp::User;

use strict;
use warnings;

use File::Spec;
use Params::Validate qw( :types validate_pos );
use RefImp::Resources::LDAP;

class RefImp::User {
    table_name => 'users',
    id_by => {
        id => { is => 'Integer', },
    },
    has_optional => {
        name => { is => 'Text', doc => 'Login for the user.', },
        #email => { is => 'Text', doc => 'Login for the user.', },
        first_name => { is => 'Text', doc => 'First name of the user.', },
        last_name => { is => 'Text', doc => 'Last name of the user.', },
    },
    has_many => {
        functions => {
            is => 'RefImp::User::Function',
            reverse_as => 'user',
            doc => 'User functions.',
        },
    },
    data_source => RefImp::Config::get('ds_oltp'),
};

sub email_domain { 'wustl.edu' }
sub email {
    my $self = shift;
    # Try LDAP first...
    my $mail = RefImp::Resources::LDAP->mail_for_unix_login( $self->name );
    return $mail if $mail;
    # Return the unix_login and domain
    join('@', $self->name, $self->email_domain);
}

sub first_initial { uc substr($_[0]->first_name, 0, 1); }
sub last_name_uc { sprintf('%s', join(' ', map { ucfirst } split(' ', $_[0]->last_name))); }

1;

