#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::More tests => 1;
use Test::Exception;

my %setup = ( class => 'RefImp::Pacbio::Run', );
subtest 'new' => sub{
    plan tests => 4;

    use_ok($setup{class}) or die;

    my $directory = dir( TestEnv::test_data_directory_for_package($setup{class}) );
    ok(-d "$directory", "example run directory exists");

    my $run = $setup{class}->new(directory => $directory);
    ok($run, 'create run');
    ok($run->directory, 'directory');

    $setup{run} = $run;

};

done_testing();
