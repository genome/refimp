package Util::GCP;

use strict;
use warnings 'FATAL';

use IPC::Cmd 'run';

class Util::GCP {
    is => 'UR::Singleton',
};

sub _run_command {
    my ($class, $cmd) = @_;

    $class->fatal_message('No command given to run!') if !$cmd or !@$cmd;

    $class->status_message('RUN: %s', join (' ', @$cmd));
    my($success, $error_message, $buffer, $stdout, $stderr) = IPC::Cmd::run(command => $cmd, verbose => 0);
    return $stdout if $success;
    $class->status_message(@$stderr);
    $class->status_message($error_message);
    $class->fatal_message("Failed to run gsutil!");

}

sub rsync {
    my ($class, $src, $dst) = @_;

    $class->fatal_message('No source given to rsync!') if not $src;
    $class->fatal_message('No destination given to rsync!') if not $dst;
    $class->_run_command([ 'gsutil', 'rsync', '-r', $src, $dst ]);

}

sub ls {
    my ($class, $src) = @_;

    $class->fatal_message('No source given to ls!') if not $src;
    $class->fatal_message('Do not include stars (*) at the end of source to ls: %s', $src) if not $src;
    my $out = $class->_run_command([ 'gsutil', 'ls', '-l', $src ]);
    $class->_parse_ls($out);

}

sub _parse_ls {
    my ($class, $out) = @_;

    $class->fatal_message("No output given to parse!") if not $out;

    my @contents;
    my $objects_line = pop @$out;
    for my $line ( @$out ) {
        chomp $line;
        $line =~ s/^\s+//;
        my @tokens = split(/\s+/, $line);
        my %obj;
        if ( @tokens > 1 ) {
            $obj{size} = $tokens[0];
            $obj{date} = $tokens[1];
            $obj{name} = $tokens[2];
            $obj{type} = 'f';
        }
        else {
            $obj{qw/ name /} = $tokens[0];
            $obj{type} = 'd';
        }
        push @contents, \%obj;
    }

    \@contents;
}

1;
