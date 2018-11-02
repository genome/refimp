#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Test::More tests => 1;

subtest "create" => sub{
    plan tests => 9;

    my $pkg = 'Tenx::Assembly';
    use_ok($pkg) or die;
    use_ok('Tenx::Reads') or die;

    my $assembly = $pkg->create(
        url => '/tmp',
        reads => Tenx::Reads->__define__(directory => '/tmp/', sample_name => 'TEST-TESTY-MCTESTERSON'),
        status => 'running',
    );
    ok($assembly, 'create tenx assembly');

    ok($assembly->id, 'assembly id');
    ok($assembly->url, 'assembly location');
    is($assembly->reads_id, $assembly->reads->id, 'assembly reads');
    ok($assembly->status, 'assembly status');

    ok($assembly->__display_name__, 'display name');

    ok(UR::Context->commit, 'commit');

};

done_testing();
