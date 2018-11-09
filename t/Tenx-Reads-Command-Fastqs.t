#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::Exception;
use Test::More tests => 1;

my %test = ( class => 'Tenx::Reads::Command::Fastqs' );
subtest 'execute' => sub{
    plan tests => 6;

    use_ok($test{class}) or die;

    $test{data_dir} = TestEnv::test_data_directory_for_class('RefImp::Reads')->subdir('sample-sheet');
    ok(-d "$test{data_dir}", 'data dir exists');

    my $cmd = $test{class}->create(
        directory => "$test{data_dir}",
    );
    ok($cmd, 'create cmd');

    my $out;
    open local(*STDOUT), '>', \$out or die $!;

    lives_ok(sub{ $cmd->execute; }, 'execute');
    ok($cmd->result, 'execute succeeded');

    like($out, qr/^SAMPLE\s+FASTQ_PATH\s+\n\-{6}\s+\-{10}\s+\nM_FA-1CNTRL-Control_10x/, 'correct output');

};

done_testing();
