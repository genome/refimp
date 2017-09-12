#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my $pkg = 'Refimp::Tenx::Command::Reference::Create';
use_ok($pkg) or die;
my $taxon = Refimp::Taxon->get(1);

subtest 'create' => sub{
    plan tests => 8;

    my $name = "TESTREF";
    my $ref = Refimp::Tenx::Reference->get(name => $name);
    ok(!$ref, 'reference does not exist');

    my $cmd;
    lives_ok(
        sub{ $cmd = Refimp::Tenx::Command::Reference::Create->execute(
                name => $name,
                directory => '/tmp',
                taxon => $taxon,
            ); },
        'execute',
    );
    ok($cmd->result, 'execute successful');

    $ref = Refimp::Tenx::Reference->get(name => $name);
    ok($ref, 'reference created');
    is($ref->name, $name, 'name set');
    is($ref->directory, '/tmp', 'directory set');
    is($ref->taxon, $taxon, 'taxon set');

    ok(UR::Context->commit, 'commit');

};

subtest 'create fails' => sub{
    plan tests => 1;

    throws_ok(
        sub{ Refimp::Tenx::Command::Reference::Create->execute(
                name => 'BLAH',
                directory => '/blah',
                taxon => $taxon,
            ); },
        qr/Reference directory does not exist: \/blah/,
        'fails with invalid directory',
    );

};

done_testing();
