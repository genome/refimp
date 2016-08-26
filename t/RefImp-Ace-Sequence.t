#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use Test::More tests => 1;

subtest 'setup' => sub{
    plan tests => 2;

    my $pkg = 'RefImp::Ace::Sequence';
    use_ok($pkg) or die;

    my $seq = $pkg->new;
    isa_ok($seq, $pkg);

};

done_testing();
