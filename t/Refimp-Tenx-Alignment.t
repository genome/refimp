#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 1;

subtest "create" => sub{
    plan tests => 10;

    my $pkg = 'Refimp::Tenx::Alignment';
    use_ok($pkg) or die;
    use_ok('Refimp::Tenx::Reads') or die;
    use_ok('Refimp::Tenx::Reference') or die;

    my $alignment = $pkg->create(
        directory => '/tmp',
        reads => Refimp::Tenx::Reads->__define__(directory => '/tmp/', sample_name => 'TEST-TESTY-MCTESTERSON'),
        reference => Refimp::Tenx::Reference->__define__(directory => '/tmp', name => 'REF'),
        status => 'running',
    );
    ok($alignment, 'create tenx alignment');

    ok($alignment->id, 'alignment id');
    ok($alignment->directory, 'alignment directory');
    is($alignment->reads_id, $alignment->reads->id, 'alignment reads');
    is($alignment->reference_id, $alignment->reference->id, 'alignment reference');
    ok($alignment->status, 'alignment status');

    ok(UR::Context->commit, 'commit');

};

done_testing();
