#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 3;

my $pkg = 'RefImp::Project::NotesFile';
use_ok($pkg) or die;

my $notes_file;
subtest 'new' => sub{
    plan tests => 3;

    my $data_dir = TestEnv::test_data_directory_for_package($pkg);

    throws_ok(sub{ $notes_file = $pkg->new(); }, qr/but 2 were expected/, 'new fails w/o file');
    throws_ok(
        sub{ $notes_file = $pkg->new( File::Spec->join($data_dir, 'doesnotexist.notes') ); },
        qr/File does not exist\!/,
        'new fails w/ invalid file',
    );

    lives_ok( sub{ $notes_file = $pkg->new( File::Spec->join($data_dir, 'clone.notes') ); }, 'new w/ valid file');


};

subtest 'finishers' => sub{
    plan tests => 2;

    my @prefinishers = $notes_file->prefinishers;
    is_deeply(\@prefinishers, [qw/ sprzybys /], 'prefinishers');

    my @finishers = $notes_file->finishers;
    is_deeply(\@finishers, [qw/ sdauphin /], 'finishers');

};

done_testing();
