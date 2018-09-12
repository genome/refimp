#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;

use Test::Exception;
use Test::More tests => 4;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    $test{pkg} = 'Tenx::Reads';
    use_ok($test{pkg}) or die;

    $test{sample_name} = 'TEST-TESTY-MCTESTERSON',

};

subtest "create" => sub{
    plan tests => 5;

    my $reads = $test{pkg}->create(
        directory => '/tmp',
        sample_name => $test{sample_name},
    );
    ok($reads, 'create tenx readserence');
    $test{reads} = $reads;

    ok($reads->id, 'reads id');
    ok($reads->sample_name, 'reads sample_name');
    ok($reads->directory, 'reads directory');

    ok(UR::Context->commit, 'commit');

};

subtest 'type' => sub{
    plan tests => 2;

    my $reads = $test{reads};
    is($reads->type, 'wgs', 'type is wgs w/o tagets_path');
    $reads->targets_path('/tmp');
    is($reads->type, 'targeted', 'type is targeted w/ tagets_path');

};

subtest 'create fails' => sub{
    plan tests => 3;

    throws_ok(
        sub{ $test{pkg}->create(
                sample_name => $test{sample_name},
                directory => '/blah',
                targets_path => '/tmp'
            ); },
        qr/Reads directory does not exist/,
        'fails with invalid directory',
    );

    throws_ok(
        sub{ $test{pkg}->create(
                sample_name => $test{sample_name},
                directory => '/var',
                targets_path => '/blah'
            ); },
        qr/Targets path does not exist/,
        'fails with invalid targets_path',
    );

    throws_ok(
        sub{ $test{pkg}->create(
                sample_name => $test{sample_name},
                directory => '/tmp',
                targets_path => '/tmp'
            ); },
        qr/Found existing reads with directory/,
        'fails when recreating w/ same directory',
    );

};

done_testing();
