#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;
use Test::More tests => 2;

my %test = ( class => 'Pacbio::Assembly::Duration');
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{class}) or die;
    $test{data_dir} = TestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}, 'data dir exists');

};

subtest 'blocking' => sub{
    plan tests => 1;

    my $dir = $test{data_dir}->subdir('blocking');
    ok(-d $dir, 'blocking data dir exists');

};

done_testing();
