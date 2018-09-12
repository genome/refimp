#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;

use Test::Exception;
use Test::More tests => 3;

my $pkg = 'Tenx::Reference';
use_ok($pkg) or die;

subtest "create" => sub{
    plan tests => 6;

    my $ref = $pkg->create(
        name => 'TESTY MCTESTERSON',
        directory => '/tmp',
        taxon_name => 'human',
    );
    ok($ref, 'create tenx reference');

    ok($ref->id, 'reference id');
    ok($ref->name, 'reference name');
    ok($ref->directory, 'reference directory');
    ok($ref->taxon_name, 'reference taxon_name');

    ok(UR::Context->commit, 'commit');

};

subtest 'create fails' => sub{
    plan tests => 3;

    throws_ok(
        sub{ $pkg->create(name => 'TESTY MCTESTERSON', directory => '/blah', taxon_name => 'human'); },
        qr/Reference directory does not exist/,
        'failed to create w/ invalid directory',
    );

    throws_ok(
        sub{ $pkg->create(name => 'TESTY MCTESTERSON', directory => '/tmp', taxon_name => 'human'); },
        qr/Found existing reference with name/,
        'failed to create when existing reference has same name',
    );

    throws_ok(
        sub{ $pkg->create(name => 'BLAH', directory => '/tmp', taxon_name => 'human'); },
        qr/Found existing reference with directory/,
        'failed to create when existing reference has same directory',
    );
 
};

done_testing();
