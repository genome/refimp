#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 1;

subtest "create" => sub{
    plan tests => 7;

    use_ok('RefImp::Assembly') or die;

    my $assembly = RefImp::Assembly->create(
        name => 'TESTY MCTESTERSON',
        directory => '/tmp',
        taxon_id => 1,
    );
    ok($assembly, 'create assembly');

    ok($assembly->id, 'assembly id');
    ok($assembly->name, 'assembly name');
    ok($assembly->directory, 'assembly directory');
    ok($assembly->taxon, 'assembly taxon');

    ok(UR::Context->commit, 'commit');

};

done_testing();
