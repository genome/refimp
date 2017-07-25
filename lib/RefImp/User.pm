package RefImp::User;

use strict;
use warnings;

use File::Spec;
use Params::Validate qw( :types validate_pos );
use RefImp::Resources::LDAP;
use Params::Validate qw/ :types validate_pos /;

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

sub parse_name {
    my ($class, $name) = validate_pos(@_, {isa => __PACKAGE__}, {is => SCALAR});

    $name =~ s/\.//g;
    my @name_parts = split /\s+/, $name;

    my $first = shift @name_parts;
    $class->fatal_message('Expected a last name in "%s"', $name) if not @name_parts;
    my $last = pop @name_parts;

    return {
        first => $first,
        last => $last,
        initials => join('', map {"$_."} map {uc $_} map {m/^(.)/} ($first, @name_parts)),
    };
}

1;
