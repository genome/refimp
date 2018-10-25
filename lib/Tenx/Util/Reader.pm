package Tenx::Util::Reader;

use strict;
use warnings 'FATAL';

use IO::File;

sub location { $_[0]->{location} }
sub handle { $_[0]->{handle} }

sub getline { $_[0]->handle->getline }
sub getlines { $_[0]->handle->getlines }
sub reset { $_[0]->handle->seek(0, 0); $_[0] }

sub new {
    my ($class, $location) = @_;
    die "No location given to create reader!" if not $location;
    my $file = $class->test_location_existence($location);
    die "Location to create reader does not exist! $location" if not $file;

    my $handle = IO::File->new("$file", 'r');
    die "Failed to open file! $file!" if not $handle;

    my %self = (
        location => "$location",
		handle => $handle,
    );
	bless \%self, $class;

}

1;
