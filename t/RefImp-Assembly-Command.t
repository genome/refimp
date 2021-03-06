#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;
use Test::More tests => 2;

my %test = ( class => 'RefImp::Assembly::Command' );
use_ok($test{class}) or die;

my @expected_sub_command_names = (qw/ list create submission submit /);
is_deeply([$test{class}->sorted_sub_command_names], \@expected_sub_command_names, 'sub command names');

done_testing();
