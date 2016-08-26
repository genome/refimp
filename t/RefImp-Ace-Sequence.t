#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 2;

my $pkg = 'RefImp::Ace::Sequence';

subtest 'setup' => sub{
    plan tests => 1;

    use_ok($pkg) or die;

};

my $seq;
subtest 'new' => sub{
    plan tests => 4;

    throws_ok(sub{ $pkg->new; }, qr/No bases given/, 'new fails w/o bases');

    my $bases = "AA***TTT*CCC****GGGG**";
    $seq = $pkg->new(bases => $bases);
    isa_ok($seq, $pkg);

    my $end = length($bases) - 1;
    my @expected_unpadded_to_padded = (qw/ 0 1 5 6 7 9 10 11 16 17 18 19 /);
    is_deeply($seq->{unpadded_to_padded}, \@expected_unpadded_to_padded, 'unpadded_to_padded');
    my @expected_padded_to_unpadded = (qw/ 0 1 * * * 2 3 4 * 5 6 7 * * * * 8 9 10 11 * * /);
    is_deeply($seq->{padded_to_unpadded}, \@expected_padded_to_unpadded, 'padded_to_unpadded');

};

done_testing();
