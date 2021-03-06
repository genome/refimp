#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use Test::More tests => 1;

subtest 'group' => sub{
    plan tests => 4;

    use_ok('RefImp::Disk::Group') or die;

    my %params = (
        disk_group_name => 'refimp',
    );
    my $group = RefImp::Disk::Group->create(%params);
    ok($group, 'create group');

    for my $attr ( keys %params ) {
        is($group->$attr, $params{$attr}, $attr);
    }

    ok(UR::Context->commit, 'commit');

};

done_testing();
