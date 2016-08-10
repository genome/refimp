#!/usr/bin/env lims-perl

use strict;
use warnings;
use Test::More;
use Test::PerlDashC;
use FindBin '$Bin';
use Path::Class qw(dir);
use Try::Tiny;
use IPC::Open3;
use POSIX ":sys_wait_h";

my $display_number = 18;
my $pid;

$SIG{INT} = sub {
    kill INT => $pid;
};

do {
    $display_number++;
    diag("Trying DISPLAY :$display_number");
    my $stdout = IO::Handle->new;
    my $stderr = IO::Handle->new;
    $pid = open3(undef, $stdout, $stderr, qw(Xvfb), ":$display_number", qw(-screen 0 1024x768x24 -fbdir /var/tmp));
    sleep(3);
} while ((waitpid($pid, WNOHANG) == $pid) && $display_number < 300);
$ENV{DISPLAY} = ":$display_number";

my $wait_result = waitpid($pid, WNOHANG);
ok((grep {$wait_result == $_} (-1, 0)) ? 1 : 0, 'Xvfb is running');

my $result = 1;
try {
    my $lib_dir = dir($Bin)->parent()->subdir('lib');
    my $bin_dir = dir($Bin)->parent()->subdir('bin');


    Test::PerlDashC->new(
        dirs => [
            Test::PerlDashC::Dir->new(
                path       => $lib_dir,
            ),
            Test::PerlDashC::Dir->new(
                path       => $bin_dir,
            ),
        ],
    )->execute();
}
catch {
    $result = 0;
};

kill INT => $pid;
waitpid($pid, 0);
ok($result, 'Tests ran without dying');

done_testing;
