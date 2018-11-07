#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    %test = (
        class => 'RefImp::Refseq',
        taxon => RefImp::Taxon->get(1),
    );
    use_ok($test{class}) or die;
    ok($test{taxon}, 'got taxon');

};

subtest "create" => sub{
    plan tests => 6;

    my $ref = $test{class}->create(
        name => 'TESTY MCTESTERSON',
        url => '/tmp',
        taxon => $test{taxon},
    );
    ok($ref, 'create tenx refseq');

    ok($ref->id, 'refseq id');
    ok($ref->name, 'refseq name');
    ok($ref->url, 'refseq url');
    is($ref->taxon, $test{taxon}, 'refseq taxon');

    ok(UR::Context->commit, 'commit');

};

subtest 'create fails' => sub{
    plan tests => 2;

    throws_ok(
        sub{ $test{class}->create(name => 'TESTY MCTESTERSON', url => '/tmp', taxon => $test{taxon}); },
        qr/Found existing refseq with name/,
        'failed to create when existing refseq has same name',
    );

    throws_ok(
        sub{ $test{class}->create(name => 'BLAH', url => '/tmp', taxon => $test{taxon}); },
        qr/Found existing refseq with url/,
        'failed to create when existing refseq has same url',
    );
 
};

done_testing();
