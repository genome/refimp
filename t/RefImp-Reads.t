#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 4;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    $test{pkg} = 'RefImp::Reads';
    use_ok($test{pkg}) or die;

    $test{sample_name} = 'TEST-TESTY-MCTESTERSON',

};

subtest "create" => sub{
    plan tests => 6;

    my $reads = $test{pkg}->create(
        sample_name => $test{sample_name},
        tech => 'tenx',
        url => '/tmp',
    );
    ok($reads, 'create refimp reads');
    $test{reads} = $reads;

    ok($reads->id, 'reads id');
    ok($reads->sample_name, 'reads sample_name');
    ok($reads->tech, 'reads tech');
    ok($reads->url, 'reads url');

    ok(UR::Context->commit, 'commit');

};

subtest 'type' => sub{
    plan tests => 2;

    my $reads = $test{reads};
    is($reads->type, 'wgs', 'type is wgs w/o tagets_url');
    $reads->targets_url('/tmp');
    is($reads->type, 'targeted', 'type is targeted w/ tagets_url');

};

subtest 'create fails' => sub{
    plan tests => 2;

    throws_ok(
        sub{ $test{pkg}->create(
                sample_name => $test{sample_name},
                targets_url => '/blah',
                tech => 'tenx',
                url => '/var',
            ); },
        qr/Targets url does not exist/,
        'fails with invalid targets_url',
    );

    throws_ok(
        sub{ $test{pkg}->create(
                sample_name => $test{sample_name},
                targets_url => '/tmp',
                tech => 'tenx',
                url => '/tmp',
            ); },
        qr/Found existing reads with url/,
        'fails when recreating w/ same url',
    );

};

done_testing();
