#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    %test = ( class => 'Tenx::Reads::Command::QcSummary' );
    use_ok($test{class}) or die;

    $test{data_dir} = TestEnv::test_data_directory_for_class('RefImp::Reads')->subdir('sample-sheet');
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

    like($out, qr/SAMPLE\s+BARCODE_EXACT_MATCH_RATIO\s+BARCODE_Q30_BASE_RATIO\s+BC_ON_WHITELIST/, 'correct output');
    like($out, qr/\n------\s+-------------------------\s+----------------------\s+---------------/, 'correct output');
    like($out, qr/\nM_FA-1CNTRL-Control_10x\s+0.93/, 'correct output');

};


subtest 'execute show all' => sub{
    plan tests => 6;

    my $cmd = $test{class}->create(
        directory => "$test{data_dir}",
        show_all => 1,
    );
    ok($cmd, 'create cmd');

    my $out;
    open local(*STDOUT), '>', \$out or die $!;

    lives_ok(sub{ $cmd->execute; }, 'execute');
    ok($cmd->result, 'execute succeeded');

    like($out, qr/SAMPLE\s+LANE\s+BARCODE_EXACT_MATCH_RATIO\sBARCODE_Q30_BASE_RATIO\sBC_ON_WHITELIST/, 'correct output');
    like($out, qr/\n------\s+----\s+-------------------------\s----------------------\s---------------/, 'correct output');
    like($out, qr/\nM_FA-1CNTRL-Control_10x\s+2\s+0.93/, 'correct output');

};

done_testing();
