#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 2;

my %test;
subtest "create" => sub{
    plan tests => 6;

    $test{pkg} = 'RefImp::Tenx::Reads';
    use_ok($test{pkg}) or die;

    my $reads = $test{pkg}->create(
        directory => '/tmp',
        sample_name => 'TEST-TESTY-MCTESTERSON',
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

done_testing();
