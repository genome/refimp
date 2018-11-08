#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

use Test::More tests => 1;

subtest "create" => sub{
    plan tests => 10;

    my $pkg = 'RefImp::Alignment';
    use_ok($pkg) or die;
    use_ok('RefImp::Reads') or die;
    use_ok('RefImp::Refseq') or die;

    my $alignment = $pkg->create(
        url => '/tmp',
        reads => RefImp::Reads->__define__(url => '/tmp/', sample_name => 'TEST-TESTY-MCTESTERSON'),
        refseq => RefImp::Refseq->__define__(url => '/tmp', name => 'REF'),
        status => 'running',
    );
    ok($alignment, 'create tenx alignment');

    ok($alignment->id, 'alignment id');
    ok($alignment->url, 'alignment url');
    is($alignment->reads_id, $alignment->reads->id, 'alignment reads');
    is($alignment->refseq_id, $alignment->refseq->id, 'alignment refseq');
    ok($alignment->status, 'alignment status');

    ok(UR::Context->commit, 'commit');

};

done_testing();
