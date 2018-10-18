#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::More tests => 5;
use Test::Exception;

use TenxTestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    %test = ( class => 'Tenx::Util::Run::Log' );

    use_ok($test{class});

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Util::Run');
    ok(-d $test{data_dir}, 'data dir exists');

};

subtest 'fails' => sub{
    plan tests => 1;

    throws_ok(sub{ $test{class}->create; }, qr//, 'fails w/o log_file');

};

subtest 'success log' => sub{
    plan tests => 2;

    my $log = $test{class}->create(log_file => $test{data_dir}->subdir('supernova-success')->file('_log'));
    ok($log, 'created log');
    is($log->run_status, 'success', 'run status');

};

subtest 'running log' => sub{
    plan tests => 2;

    my $log = $test{class}->create(log_file => $test{data_dir}->subdir('supernova-running')->file('_log'));
    ok($log, 'created log');
    is($log->run_status, 'running', 'run status');

};

subtest 'fail log' => sub{
    plan tests => 2;

    my $log = $test{class}->create(log_file => $test{data_dir}->subdir('longranger-fail')->file('_log'));
    ok($log, 'created log');
    is($log->run_status, 'failed', 'run status');

};

done_testing();
