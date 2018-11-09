#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::More tests => 1;

subtest "create" => sub{
    plan tests => 11;

    my $pkg = 'RefImp::Assembly';
    use_ok($pkg) or die;
    use_ok('RefImp::Reads') or die;

    my $assembly = $pkg->create(
        name => 'SAMPLE1',
        url => '/tmp',
        tech => 'tenx',
        status => 'running',
        reads => RefImp::Reads->__define__(url => '/tmp/', sample_name => 'TEST-TESTY-MCTESTERSON'),
        taxon => RefImp::Taxon->get(1),
    );
    ok($assembly, 'create assembly');

    ok($assembly->id, 'assembly id');
    ok($assembly->url, 'assembly location');
    ok($assembly->status, 'assembly status');
    is($assembly->taxon_id, 1, 'assembly taxon_id');
    is($assembly->tech, 'tenx', 'assembly tech');
    is($assembly->reads_id, $assembly->reads->id, 'assembly reads_id');

    ok($assembly->__display_name__, 'display name');

    ok(UR::Context->commit, 'commit');

};

done_testing();
