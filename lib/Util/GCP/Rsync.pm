package Util::GCP::Rsync;

use strict;
use warnings 'FATAL';

sub rsync {
    my ($class, $src, $dst) = @_;

    die 'No source given to rsync!' if not $src;
    die 'No destination given to rsync!' if not $dst;

    my @cmd = ( 'gsutil', 'rsync', '-r', $src, $dst );
	print STDERR 'RUN: %s', join (' ', @cmd);
    my $rv = system(@cmd);
	die "Failed to run gsutil rsync: $?" if $rv;

}

1;
