#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 1;

subtest "create" => sub{
    plan tests => 6;

    my $pkg = 'RefImp::Tenx::Reads';
    use_ok($pkg) or die;

    my $ref = $pkg->create(
        directory => '/tmp',
        sample_name => 'TEST-TESTY-MCTESTERSON',
    );
    ok($ref, 'create tenx reference');

    ok($ref->id, 'reads id');
    ok($ref->sample_name, 'reads sample_name');
    ok($ref->directory, 'reads directory');

    ok(UR::Context->commit, 'commit');

};

done_testing();
