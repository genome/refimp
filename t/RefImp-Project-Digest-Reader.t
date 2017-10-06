#!/usr/bin/env perl

use strict;
use warnings;

use lib '.';

use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 3;
use YAML;

my $pkg = 'RefImp::Project::Digest::Reader';
use_ok($pkg) or die;

my $reader;
subtest 'new' => sub{
    plan tests => 3;

    throws_ok(sub{ $pkg->new; }, qr/No sizes file given/, 'new fails w/o sizes file');
    throws_ok(sub{ $pkg->new(file => 'blah'); }, qr/Invalid sizes file \(blah\) given to reader/, 'new fails with non existing sizes file');

    my $data_directory = TestEnv::test_data_directory_for_package($pkg);
    my $sizes_file = File::Spec->join($data_directory, '150421a.sizes');
    $reader = $pkg->new(file => $sizes_file);
    ok($reader, 'create reader');

};

subtest 'next_for_project' => sub{
    plan tests => 5;

    throws_ok(sub{ my $digest = $reader->next_for_project; }, qr/but 2 were expected/, 'next_for_project fails w/o project');

    my $data_directory = TestEnv::test_data_directory_for_package($pkg);
    my @expected_digests = YAML::LoadFile( File::Spec->join($data_directory, '150421a.sizes.yml') );

    $reader->{fh}->seek(0, 0);
    my $project_name = 'VMRC59-479B11';
    my $digest = $reader->next_for_project($project_name);
    is_deeply($digest, $expected_digests[1], "digest for $project_name matches");

    ok(!$reader->next_for_project($project_name), "no more digests for $project_name");

    $reader->{fh}->seek(0, 0);
    $project_name = 'VMRC59-479B4';
    $digest = $reader->next_for_project($project_name);
    is_deeply($digest, $expected_digests[0], "digest for $project_name matches");
    $digest = $reader->next_for_project($project_name);
    is_deeply($digest, $expected_digests[2], "digest for $project_name matches");

};

done_testing();
