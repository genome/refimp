#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 4;

my $class = 'RefImp::Test';
use_ok($class) or die;

subtest 'test_data_directory' => sub {
    plan tests => 3;

    my $test_data_directory = $class->test_data_directory;
    ok($test_data_directory, 'test_data_directory');
    ok(-d $test_data_directory, 'test_data_directory exists');
    like($test_data_directory, qr/t.d$/, 'test_data_directory named correctly');

};

subtest 'test_data_directory_for_package' => sub {
    plan tests => 3;

    throws_ok(
        sub{ $class->test_data_directory_for_package(); },
        qr/but 2 were expected/,
        'test_data_directory_for_package fails w/o pkg',
    );
    my $test_data_directory_for_package = $class->test_data_directory_for_package("RefImp");
    ok($test_data_directory_for_package, 'test_data_directory_for_package RefImp');
    like($test_data_directory_for_package, qr/t.d\/RefImp$/, 'test_data_directory_for_package named correctly');

};

subtest 'seqmgr_test_data_directory' => sub{
    plan tests => 1;

    my $seqmgr = $ENV{SEQMGR};
    my $seqmgr_test_data_directory = $class->set_seqmgr_test_data_directory;
    isnt($seqmgr_test_data_directory, $seqmgr, 'set_seqmgr_test_data_directory');

};

done_testing();
