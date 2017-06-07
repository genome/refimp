#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 4;

my $longranger_pkg = 'RefImp::Tenx::Command::Longranger';
my $pkg = join('::', $longranger_pkg, 'Status');
use_ok($pkg) or die;
my $output;

subtest 'succeded determined by log' => sub{ 
    plan tests => 3;

    my $data_dir = dir( TestEnv::test_data_directory_for_package($longranger_pkg) );
    my $succeeded_dir = $data_dir->subdir('succeeded');
    ok(-d $succeeded_dir, 'succeeded dir exists');
    
    open local(*STDERR), '>', \$output or die $!;
    lives_ok(sub{ $pkg->execute(directory => $succeeded_dir->stringify); }, 'alignment status is succeeded'); 
    like($output, qr/Log status:\s+SUCCEEDED/, 'output');

};

subtest 'failed determined by log' => sub{
    plan tests => 3;

    my $data_dir = dir( TestEnv::test_data_directory_for_package($longranger_pkg) );
    my $failed_dir = $data_dir->subdir('failed');
    ok(-d $failed_dir->stringify, 'failed dir exists');

    open local(*STDERR), '>', \$output or die $!;
    lives_ok(sub{ $pkg->execute(directory => $failed_dir->stringify); }, 'alignment status is failed'); 
    like($output, qr/Log status:\s+FAILED/, 'output');

};

subtest 'running determined by log and journal' => sub{
    plan tests => 3;

    my $data_dir = dir( TestEnv::test_data_directory_for_package($longranger_pkg) );
    my $running_dir = $data_dir->subdir('running');
    ok(-d $running_dir->stringify, 'running dir exists');
    my $journal = $running_dir->subdir('journal');
    system('touch', $journal->stringify);

    open local(*STDERR), '>', \$output or die $!;
    lives_ok(sub{ $pkg->execute(directory => $running_dir->stringify); }, 'alignment status is running'); 
    like($output, qr/Journal status:\s+PASS/, 'output');

};

done_testing();
