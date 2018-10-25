#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::More tests => 1;
use Test::Exception;

use TenxTestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 3;

    %test = ( class => 'Tenx::Util::Reader::GCE' );
    use_ok($test{class});

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Util::Reader');
    ok(-d $test{data_dir}, 'data dir exists');

    $test{log_file} = $test{data_dir}->file('_log');
    ok(-s $test{log_file}, 'log file exists');

};

done_testing();
