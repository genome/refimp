package Util::GCP;

use strict;
use warnings 'FATAL';

class Util::GCP {
    is => 'UR::Singleton',
};

sub _run_command {
    my ($class, $cmd) = @_;

    die 'No command given to run!' if !$cmd or !@$cmd;

    $class->status_message('RUN: %s', join (' ', @$cmd));
    my $rv = system(@$cmd);
	$class->fatal_message("Failed to run gsutil rsync: $?") if $rv;

}

sub rsync {
    my ($class, $src, $dst) = @_;

    die 'No source given to rsync!' if not $src;
    die 'No destination given to rsync!' if not $dst;
    $class->_run_command([ 'gsutil', 'rsync', '-r', $src, $dst ]);

}

1;
