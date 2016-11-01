#!/usr/bin/env perl5.10.1

use strict;
use warnings;

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

    throws_ok(sub{ $pkg->new; }, qr/ERROR No sizes file given/, 'new fails w/o sizes file');
    throws_ok(sub{ $pkg->new(file => '/blah'); }, qr/ERROR Failed to open/, 'new fails with non existing sizes file');

    my $data_directory = TestEnv::test_data_directory_for_package($pkg);
    my $sizes_file = File::Spec->join($data_directory, '150421a.sizes');
    $reader = $pkg->new(file => $sizes_file);
    ok($reader, 'create reader');

};

subtest 'next' => sub{
    plan tests => 4;

    my $data_directory = TestEnv::test_data_directory_for_package($pkg);
    my @expected_digests = YAML::LoadFile( File::Spec->join($data_directory, '150421a.sizes.yml') );

    my $digest = $reader->next;
    is_deeply($digest, $expected_digests[0], 'digest 1 matches');

    $digest = $reader->next;
    is_deeply($digest, $expected_digests[1], 'digest 2 matches');

    $digest = $reader->next;
    is_deeply($digest, $expected_digests[2], 'digest 3 matches');

    ok(!$reader->next, 'done reading');

};

done_testing();
