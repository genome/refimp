#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 2;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    %test = (
        pkg => 'RefImp::Tenx::Command::Reads::Create',
        sample_name => 'TESTSAMPLE',
    );
    use_ok($test{pkg}) or die;

};

subtest 'create' => sub{
    plan tests => 8;

    my $sample_name = "TESTSAMPLE";
    my $reads = RefImp::Tenx::Reads->get(sample_name => $sample_name);
    ok(!$reads, 'reads does not exist');

    my $cmd;
    lives_ok(
        sub{ $cmd = $test{pkg}->execute(
                sample_name => $sample_name,
                directory => '/tmp',
                targets_path => '/tmp',
            ); },
        'execute',
    );
    ok($cmd->result, 'execute successful');

    $reads = RefImp::Tenx::Reads->get(sample_name => $sample_name);
    ok($reads, 'reads created');
    is($reads->sample_name, $sample_name, 'sample_name set');
    is($reads->directory, '/tmp', 'directory set');
    is($reads->targets_path, '/tmp', 'targets_path set');

    ok(UR::Context->commit, 'commit');

};

done_testing();
