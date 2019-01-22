#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my %test = ( class => 'Pacbio::Assembly::Command::Duration', );
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{class});

    $test{data_dir} = TestEnv::test_data_directory_for_class('Pacbio::Assembly::Run')->subdir('fs_based');
    ok(-d $test{data_dir}->stringify, 'data dir exists');

};

subtest 'fails' => sub{
    plan tests => 1;

    my $cmd = $test{class}->create(assembly => '/blah');
    throws_ok(sub{ $cmd->execute; }, qr/Assembly directory does not exist!/, 'fails without assembly');

};

subtest 'execute' => sub{
    plan tests => 2;

    my $cmd = $test{class}->create(assembly => $test{data_dir}->stringify);
    ok($cmd, 'create command');

    my $output;
    open local(*STDOUT), '>', \$output or die $!;

    my $expected_output = <<OUT;
0-rawreads 00d 00h 14m 25s
 daligner-runs 00d 00h 14m 25s
1-preads_ovl 00d 00h 06m 39s
 daligner-chunks 00d 00h 00m 01s
 daligner-combine 00d 00h 00m 00s
 daligner-gathered 00d 00h 00m 00s
 daligner-runs 00d 00h 06m 36s
 daligner-split 00d 00h 00m 00s
2-asm-falcon 00d 00h 01m 55s
3-unzip 00d 00h 49m 21s
 0-phasing phasing-chunks 00d 00h 00m 08s
 2-htigs 00d 00h 49m 12s
 2-htigs chunks 00d 00h 00m 00s
4-polish 00d 00h 04m 41s
 quiver-chunks 00d 00h 00m 00s
 quiver-run 00d 00h 04m 39s
 segregate-chunks 00d 00h 00m 00s
Total 00d 01h 17m 02s
OUT

    $cmd->execute;
    is($output, $expected_output, 'output matches');

};

done_testing();
