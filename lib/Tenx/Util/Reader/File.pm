package Tenx::Util::Reader::File;

use strict;
use warnings 'FATAL';

use base 'Tenx::Util::Reader';

sub test_location_existence {
    my ($class, $location) = @_;
    die "No location given to test file existance!" if not $location;
    ( -s $location ? $location : undef );
}

1;
