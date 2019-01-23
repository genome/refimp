package Util::IO;

use strict;
use warnings 'FATAL';

use IO::File;

sub open_file_for_writing {
    my ($file) = @_;

    die "No file given to open!" if not $file;

    return 'STDOUT' if $file eq '-';

    my $fh = IO::File->new($file, 'w') 
        or die "Failed to open $file";
    $fh;
}

1;
