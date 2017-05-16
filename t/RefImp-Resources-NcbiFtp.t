#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

subtest 'connect' => sub{
    plan tests => 2;

    my $pkg = 'RefImp::Resources::NcbiFtp';
    use_ok($pkg) or die;

    my $test_ftp = TestEnv::NcbiFtp->setup;
    my $ftp = $pkg->connect;
    is($ftp, $test_ftp, 'connected to ncbi ftp');

};

done_testing();
