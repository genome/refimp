#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Sub::Install;
use Test::Exception;
use Test::Mock::Cmd 'system' => \&system_mock;
use Test::More tests => 2;

my $system_rv = 0;
sub system_mock {
    is_deeply(\@_, [qw/ gsutil rsync -r src dest/], 'correct command');
    $system_rv;
}

my %test = ( class => 'Util::GCP' );
use_ok($test{class}) or die;

subtest 'rsync' => sub {
    plan tests => 6;

    my $err;
    open local(*STDERR), '>', \$err or die $!;
    throws_ok(sub{ $test{class}->rsync(); }, qr/No source given to rsync/, 'fails w/o source');
    throws_ok(sub{ $test{class}->rsync('src'); }, qr/No destination given to rsync/, 'fails w/o destination');
    lives_ok( sub{ $test{class}->rsync('src', 'dest'); }, 'success');
    $system_rv = 1;
    throws_ok( sub{ $test{class}->rsync('src', 'dest', 1); }, qr/Failed to run gsutil rsync/, 'handles system failure');

};

done_testing();
