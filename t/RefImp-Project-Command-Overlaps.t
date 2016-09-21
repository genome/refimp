#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Sub::Install;
use Test::Exception;
use Test::More tests => 3;

my $pkg_name = 'RefImp::Project::Command::Overlaps';
use_ok($pkg_name) or die;

my @expected_overlaps = (
    {
        'ACCESSION' => 'AC073472',
        'CLONE_NAME' => 'H_NH0627P22',
        'OVERLAP_STATUS' => 'verified',
        'SIDE' => 'Left',
        'PROJECT_STATUS' => 'submitted'
    },
    {
        'ACCESSION' => 'AC010990',
        'CLONE_NAME' => 'H_TD2536K09',
        'OVERLAP_STATUS' => 'verified',
        'SIDE' => 'Right',
        'PROJECT_STATUS' => 'submitted'
    },
    {
        'ACCESSION' => 'AC079931',
        'CLONE_NAME' => 'H_TD2594L23',
        'OVERLAP_STATUS' => 'unverified',
        'SIDE' => 'Other',
        'PROJECT_STATUS' => 'redundant'
    },
);
TestEnv::Project::setup_test_overlaps(@expected_overlaps);

my $left_neighbor = $expected_overlaps[0];
my $right_neighbor = $expected_overlaps[1];
my $overlaps;

subtest 'execute' => sub{
    plan tests => 2;

    $overlaps = $pkg_name->execute(
        project => RefImp::Project->get(1),
    );
    ok($overlaps->result, 'execute');
    is_deeply($overlaps->overlaps, \@expected_overlaps, 'overlaps');

};

subtest 'neighbors' => sub{
    plan tests => 3;

    throws_ok(sub{ $overlaps->neighbor_on}, qr/but 2 were expected/, 'neighbor_on fails w/o side');
    is_deeply($overlaps->neighbor_on('left'), $left_neighbor, 'left_neighbor');
    is_deeply($overlaps->neighbor_on('right'), $right_neighbor, 'right_neighbor');

};

done_testing();
