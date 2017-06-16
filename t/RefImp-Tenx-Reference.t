#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 1;

subtest "create" => sub{
    plan tests => 7;

    my $pkg = 'RefImp::Tenx::Reference';
    use_ok($pkg) or die;

    my $ref = $pkg->create(
        name => 'TESTY MCTESTERSON',
        directory => '/tmp',
        taxon_id => 1,
    );
    ok($ref, 'create tenx reference');

    ok($ref->id, 'reference id');
    ok($ref->name, 'reference name');
    ok($ref->directory, 'reference directory');
    ok($ref->taxon, 'reference taxon');

    ok(UR::Context->commit, 'commit');

};

done_testing();
