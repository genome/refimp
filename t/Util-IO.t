#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::Exception;
use Test::More tests => 2;

subtest 'setup' => sub{
    plan tests => 1;

   use_ok('Util::IO') or die;

};

subtest 'open_file' => sub{
    plan tests => 3;

    throws_ok(sub{ Util::IO::open_file(); }, qr//, 'fails w/o file');

    my $fh = Util::IO::open_file_for_writing('-');
    ok($fh, 'opened STDOUT');

    $fh = Util::IO::open_file_for_writing('/tmp/blah');
    ok($fh, 'opened file');
    $fh->close;

};

done_testing();
