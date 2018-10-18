#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::More tests => 2;
use Test::Exception;

use TenxTestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 3;

    %test = ( class => 'Tenx::Util::Reader::File' );
    use_ok($test{class});

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Util::Reader');
    ok(-d $test{data_dir}, 'data dir exists');

    $test{log_file} = $test{data_dir}->file('_log');
    ok(-s $test{log_file}, 'log file exists');

};

subtest 'new' => sub{
    plan tests => 2;

    my $reader = $test{class}->new($test{log_file});
    ok($reader, 'created reader');
    ok($reader->getline, 'getline from handle');

};

done_testing();
