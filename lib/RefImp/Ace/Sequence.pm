package RefImp::Ace::Sequence;

use strict;
use warnings;

sub new {
    my ($class, %params) = @_;

    my $self = bless \%params, $class;
    $self->_validate;

    $self;
}

sub _validate {
    my $self = shift;

    die "No bases given!" if not $self->{bases};
}

1;

