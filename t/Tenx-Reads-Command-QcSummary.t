#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Test::Exception;
use Test::More tests => 2;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    %test = ( class => 'Tenx::Reads::Command::QcSummary' );
    use_ok($test{class}) or die;

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Reads')->subdir('sample-sheet');
    ok(-d "$test{data_dir}", 'data dir exists');

};

subtest 'execute' => sub{
    plan tests => 6;

    my $cmd = $test{class}->create(
        directory => "$test{data_dir}",
    );
    ok($cmd, 'create cmd');

    my $out;
    open local(*STDOUT), '>', \$out or die $!;

    lives_ok(sub{ $cmd->execute; }, 'execute');
    ok($cmd->result, 'execute succeeded');

    like($out, qr/SAMPLE\s+BARCODE_EXACT_MATCH_RATIO\sBARCODE_Q30_BASE_RATIO\sBC_ON_WHITELIST/, 'correct output');
    like($out, qr/\n------\s+-------------------------\s----------------------\s---------------/, 'correct output');
    like($out, qr/\nM_FA\-1CNTRL-Control_10x\s+0.93/, 'correct ouput');

};

done_testing();
