#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

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
    my $ref = RefImp::Tenx::Reads->get(sample_name => $sample_name);
    ok(!$ref, 'reads does not exist');

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

    $ref = RefImp::Tenx::Reads->get(sample_name => $test{sample_name});
    ok($ref, 'reads created');
    is($ref->sample_name, $sample_name, 'sample_name set');
    is($ref->directory, '/tmp', 'directory set');
    is($ref->targets_path, '/tmp', 'targets_path set');

    ok(UR::Context->commit, 'commit');

};

subtest 'create fails' => sub{
    plan tests => 4;

    throws_ok(
        sub{ $test{pkg}->execute(
                sample_name => $test{sample_name},
                directory => '/blah',
                targets_path => '/tmp'
            ); },
        qr/Directory \/blah does not exist/,
        'fails with invalid directory',
    );

    throws_ok(
        sub{ $test{pkg}->execute(
                sample_name => $test{sample_name},
                directory => '/var',
                targets_path => '/blah'
            ); },
        qr/Targets path \/blah does not exist/,
        'fails with invalid targets_path',
    );

    throws_ok(
        sub{ $test{pkg}->execute(
                sample_name => $test{sample_name},
                directory => '/tmp',
                targets_path => '/tmp'
            ); },
        qr/Existing reads found for directory/,
        'fails when recreating w/ same directory',
    );

    throws_ok(
        sub{ $test{pkg}->execute(
                sample_name => $test{sample_name},
                directory => '/var',
                targets_path => '/tmp'
            ); },
        qr/Existing reads found for sample_name and targets_path/,
        'fails when recreating with sample_name and targets_path',
    );

};

done_testing();
