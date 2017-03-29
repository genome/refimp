package RefImp::User;

use strict;
use warnings;

use File::Spec;
use Params::Validate qw( :types validate_pos );
use RefImp::Resources::LDAP;

class RefImp::User {
    table_name => 'users',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        name => { is => 'Text', doc => 'Login for the user.', },
        first_name => { is => 'Text', doc => 'First name of the user.', },
        last_name => { is => 'Text', doc => 'Last name of the user.', },
    },
    has_optional => {
        email => { is => 'Text', doc => 'Email address for the user.', },
    },
    data_source => RefImp::Config::get('ds_mysql'),
};

sub first_initial { uc substr($_[0]->first_name, 0, 1); }
sub last_name_uc { sprintf('%s', join(' ', map { ucfirst } split(' ', $_[0]->last_name))); }

1;

