#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use File::Slurp;
use File::Temp;
use Path::Class;
use Test::More tests => 1;
use Test::Exception;

my %test = ( class => 'Pacbio::Run::Command::FetchDirectories', );
subtest 'execute' => sub{
    plan tests => 7;

    use_ok($test{class}) or die;

    my $xml_content = File::Slurp::slurp( TenxTestEnv::test_data_directory_for_class($test{class})->file('merged.dataset.xml') );
    ok($xml_content, "found merged data set xml");
    my $data_dir = TenxTestEnv::test_data_directory_for_class('Pacbio::Run');
    $xml_content =~ s/%TDD/$data_dir/g;
    my $tempdir = dir( File::Temp::tempdir(CLEANUP => 1) );
    my $xml_file = $tempdir->file('merged.dataset.xml');
    File::Slurp::write_file($xml_file, $xml_content);

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
    like($out, qr#6U00I7#, 'stdout');

};

done_testing();
