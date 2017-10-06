#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use lib '.';


use TestEnv;

use Test::More tests => 1;

my %test;
subtest 'volume' => sub{
    plan tests => 4;

    use_ok('RefImp::Disk::Volume') or die;

    my %params = (
        mount_path => '/tmp',
    );
    $test{volume} = RefImp::Disk::Volume->create(%params);
    ok($test{volume}, 'create volume');

    for my $attr ( keys %params ) {
        is($test{volume}->$attr, $params{$attr}, $attr);
    }

    ok(UR::Context->commit, 'commit')

};

done_testing();
