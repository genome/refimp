#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use IO::File;
use File::Spec;
use Test::More tests => 3;
use YAML;

my %setup;
subtest 'setup' => sub{
    plan tests => 3;

    $setup{pkg} = 'Refimp::Ace::Reader';
    use_ok($setup{pkg}) or die;
    
    my $test_data_dir = TestEnv::test_data_directory_for_package($setup{pkg});
    my $acefile = File::Spec->join($test_data_dir, 'HMPB-AAD13A05.fasta.ace');
    $setup{fh} = IO::File->new($acefile, 'r');
    ok($setup{fh}, 'opened acefile') or die 'Failed to open acefile';

    $setup{reader} = $setup{pkg}->new($setup{fh});
    ok($setup{reader}, 'create reader');

    my $expected_objects_yaml = File::Spec->join($test_data_dir, 'expected-objects.yaml');
    $setup{expected_objects} = YAML::LoadFile($expected_objects_yaml);

};

subtest 'next_object' => sub {
    plan tests => 1;

    my @objects;
    while ( my $object = $setup{reader}->next_object ) {
        push @objects, $object;
    }

    is_deeply(\@objects, $setup{expected_objects}, 'retrieved objects as expected');

};

subtest 'next_object_of_type' => sub{
    plan tests => 1;

    $setup{fh}->seek(0, 0);

    my @contigs;
    while ( my $contig = $setup{reader}->next_object_of_type('contig') ) {
        push @contigs, $contig;
    }

    is_deeply(\@contigs, [grep { $_->{type} eq 'contig' } @{$setup{expected_objects}}], 'retrieved contigs as expected');

};

done_testing();
