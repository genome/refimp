#!/usr/bin/env refimp-perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::More tests => 2;

my %test;
subtest 'setup' => sub{
    plan tests => 3;

    use_ok('Refimp::Disk::Assignment') or die;

    $test{group} = Refimp::Disk::Group->create(
        disk_group_name => 'Text',
    );
    ok($test{group}, 'create group');

    $test{volume} = Refimp::Disk::Volume->create(
        mount_path => '/tmp',
    );
    ok($test{volume}, 'create volume');

};

subtest 'assignment' => sub{
    plan tests => 6;

    my $assignment = Refimp::Disk::Assignment->create(
        group => $test{group},
        volume => $test{volume},
    );
    ok($assignment, 'create assignment');
    is($assignment->group, $test{group}, 'assignment group');
    is($assignment->volume, $test{volume}, 'assignment volume');

    ok(UR::Context->commit, 'commit');

    is_deeply([$test{group}->volumes], [$test{volume}], 'group volumes');
    is_deeply([$test{volume}->groups], [$test{group}], 'volume groups');

};

done_testing();
