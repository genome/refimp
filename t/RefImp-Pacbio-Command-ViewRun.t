#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::More tests => 1;
use Test::Exception;

my %test = ( class => 'RefImp::Pacbio::Command::ViewRun', );
subtest 'execute' => sub{
    plan tests => 4;

    use_ok($test{class}) or die;

    my $directory = dir( TestEnv::test_data_directory_for_package('RefImp::Pacbio::Run') )->subdir('6U00E3');
    ok(-d "$directory", "example run directory exists");

    my $cmd = $test{class}->create(
        machine_type => 'rsii',
        run_directory => "$directory",
    );
    ok($cmd, 'create command');
    lives_ok(sub{ $cmd->execute; }, 'execute');

};

done_testing();
