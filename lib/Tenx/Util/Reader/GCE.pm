package Tenx::Util::Reader::GCE;

use strict;
use warnings 'FATAL';

use base 'Tenx::Util::Reader';

use File::Temp;
use Path::Class;

sub test_location_existence {
    my ($class, $url) = @_;
    die "No location given to test gce existance!" if not $url;

    my $tempdir = dir( File::Temp::tempdir(CLEANUP => 1) );
    my $local_file = $tempdir->file( file($url)->basename );

    my @cmd = ( 'gsutil', 'cp', "$url", "$local_file" );
    system(@cmd) == 0
        or die "Failed to run: @cmd\nError: $?";
    die "Run gsutil, but no file was copied!" if not -s $local_file;

    $local_file;
}

1;
