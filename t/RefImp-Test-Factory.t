#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use Test::More tests => 2;

subtest "setup" => sub{
    plan tests => 1;

    use_ok('RefImp::Test::Factory') or die;

};

subtest "ncbi ftp" => sub{
    plan tests => 2;

    RefImp::Config::set('ncbi_ftp_host', 'ftp-host');
    RefImp::Config::set('ncbi_ftp_user', 'ftp-user');
    RefImp::Config::set('ncbi_ftp_password', 'ftp-password');

    my $ftp = RefImp::Test::Factory->setup_test_ftp;
    ok($ftp, 'setup test ncbi ftp');
    is(RefImp::Resources::NcbiFtp->connect, $ftp, 'correctly redefined Net::FTP new');

};

done_testing();

