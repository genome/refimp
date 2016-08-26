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

subtest 'new' => sub{
    plan tests => 2;

    throws_ok(sub{ $pkg->new; }, qr/No bases given/, 'new fails w/o bases');

    my $seq = $pkg->new(bases => "ATCG");
    isa_ok($seq, $pkg);

};

done_testing();
