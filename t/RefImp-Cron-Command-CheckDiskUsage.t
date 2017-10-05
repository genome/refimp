#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 2;

my %test;
subtest setup => sub{
    plan tests => 5;

    $test{pkg} = 'RefImp::Cron::Command::CheckDiskUsage';
    use_ok($test{pkg}) or die;

    $test{group} = RefImp::Disk::Group->create(disk_group_name => 'tester');
    ok($test{group}, 'create disk group');

    $test{volume} = RefImp::Disk::Volume->create(mount_path => '/tmp');
    ok($test{group}, 'create disk volume');

    my $assignment = RefImp::Disk::Assignment->create(group => $test{group}, volume => $test{volume});
    ok($assignment, 'create disk group volume assignment');

    is_deeply([$test{group}->volumes], [$test{volume}], 'disk group volumes');

};

subtest 'execute' => sub{
    plan tests => 3,

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    my $cmd = $test{pkg}->create(groups => [$test{group}]);
    ok($cmd, 'create command');
    ok($cmd->execute, 'execute');
    my $expected_output = join("\\s+", (qw/ PATH GROUP SIZE USED STATUS /))."\n/tmp\\s+";
    like($output, qr/$expected_output/, 'output matches');

};

done_testing();
