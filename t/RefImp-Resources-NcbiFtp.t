#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

subtest 'connect' => sub{
    plan tests => 2;

    my $pkg = 'RefImp::Resources::NcbiFtp';
    use_ok($pkg) or die;

    my $test_ftp = RefImp::Test::Factory->setup_test_ftp;
    my $ftp = $pkg->connect;
    is($ftp, $test_ftp, 'connected to ncbi ftp');

};

done_testing();
