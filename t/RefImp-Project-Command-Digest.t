#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::Command::Digest';
use_ok($pkg) or die;

subtest 'enzyme for code' => sub {
    plan tests => 3;

    my %codes_and_enzymes = (
        av => "AvrII",
        bg => "BglI",
        b => "BamHI",
    );
    for my $code ( sort keys %codes_and_enzymes ) {
        is($pkg->enzyme_for_code($code), $codes_and_enzymes{$code}, "got $codes_and_enzymes{$code} for $code");
    }

};

done_testing();
