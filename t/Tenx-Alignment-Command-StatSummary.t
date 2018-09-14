#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 3;

my $pkg = 'Tenx::Alignment::Command::StatSummary';
use_ok($pkg) or die;

subtest 'execute' => sub{
    plan tests => 2;

    my $data_dir = dir( TenxTestEnv::test_data_directory_for_class('Tenx::Alignment') );
    my $succeeded_dir = $data_dir->subdir('succeeded');
    ok(-d $succeeded_dir, 'succeeded dir exists');
    lives_ok(sub{ $pkg->execute(directory => $succeeded_dir->stringify); }, 'execute'); 

};

subtest 'execute failed' => sub{
    plan tests => 2;

    my $data_dir = dir( TenxTestEnv::test_data_directory_for_class('Tenx::Alignment') );
    my $failed_dir = $data_dir->subdir('failed');
    ok(-d $failed_dir->stringify, 'failed dir exists');
    throws_ok(sub{ $pkg->execute(directory => $failed_dir->stringify); }, qr/Summary file does not exist\! Has the longranger run succeeded/, 'execute fails when no summary file'); 

};

done_testing();
