#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::More tests => 1;
use Test::Exception;

my %test = ( class => 'RefImp::Pacbio::Command::FetchRunDirectories', );
subtest 'execute' => sub{
    plan tests => 7;

    use_ok($test{class}) or die;

    my $xml_file = dir( TestEnv::test_data_directory_for_package($test{class}) )->file('merged.dataset.xml');
    ok(-s "$xml_file", "example xml file exists");

    my $cmd = $test{class}->create(
        xml_file => "$xml_file",
    );
    ok($cmd, 'create command');
 
    my ($out, $err);
    open local(*STDOUT), '>', \$out or die $!;
    open local(*STDERR), '>', \$err or die $!;

    lives_ok(sub{ $cmd->execute; }, 'execute');
    like($err, qr#WARNING\: These run directories do not exist\:\n /gscmnt/gc13036/production/smrtlink_data_root/r54111_20170512_144944#, 'stderr with non existing dirs');
    like($err, qr#Found these#, 'stderr with found dir message');
    like($out, qr#/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00I7#, 'stdout');

};

done_testing();
