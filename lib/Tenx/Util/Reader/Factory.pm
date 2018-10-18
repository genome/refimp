package Tenx::Util::Reader::Factory;

use strict;
use warnings 'FATAL';

use Tenx::Util::Reader::File;
use Tenx::Util::Reader::GCE;

sub build_reader {
    my ($class, $location) = @_;

    die "No location given to build reader!" if not $location;

    if ( "$location" =~ m#^/# ) {
        return Tenx::Util::Reader::File->new($location);
    }
    elsif ( "$location" =~ m#gs://# ) {
        return Tenx::Util::Reader::GCE->new($location);
    }
    else {
		die "Do not know how to build reader from location: $location";
	}
}

1;
