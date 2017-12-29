#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use File::Slurp;
use File::Temp;
use Test::Exception;
use Test::More tests => 3;

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

subtest 'execute to stdout as html' => sub{
    plan tests => 3,

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    my $cmd = $test{pkg}->create(
        groups => [$test{group}],
        html => 1,
    );
    ok($cmd, 'create command');
    ok($cmd->execute, 'execute');

    my $expected_output = "<table><tbody><tr><th>PATH</th><th>";
    like($output, qr/$expected_output/, 'output matches');

};

subtest 'execute to output file' => sub{
    plan tests => 3;

    my $tmpdir = Path::Class::dir( File::Temp::tempdir(CLEANUP => 1) );
    my $file = $tmpdir->file('disk_check')->stringify;
    my $cmd = $test{pkg}->create(
        groups => [$test{group}],
        output_file => $file,
    );
    ok($cmd, 'create command');
    ok($cmd->execute, 'execute');

    my $expected_output = join("\\s+", (qw/ PATH GROUP SIZE USED STATUS /))."\n/tmp\\s+";
    $test{expected_output} = qr/$expected_output/;

    my $output = File::Slurp::slurp($file);
    like($output, $test{expected_output}, 'output matches');

};

done_testing();
