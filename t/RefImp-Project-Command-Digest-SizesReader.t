#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::Command::Digest::SizesReader';
use_ok($pkg) or die;

my $reader;
subtest 'new' => sub{
    plan tests => 3;

    throws_ok(sub{ $pkg->new; }, qr/ERROR No sizes file given/, 'new fails w/o sizes file');
    throws_ok(sub{ $pkg->new(file => '/blah'); }, qr/ERROR Failed to open/, 'new fails with non existing sizes file');

    my $data_directory = TestEnv::test_data_directory_for_package($pkg);
    my $sizes_file = File::Spec->join($data_directory, '150421a.sizes');
    my $reader = $pkg->new(file => $sizes_file);
    ok($reader, 'create reader');

};

done_testing();
