#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 3;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    %test = (
        pkg => 'Tenx::Alignment::Command::CreateFromDirectory',
        sample_name => 'TESTSAMPLE',
        reference => Tenx::Reference->__define__(directory => '/ref'),
        reads => Tenx::Reads->__define__(directory => '/reads', sample_name => 'TEST'),
    );
    use_ok($test{pkg}) or die;

    $test{data_dir} = dir( TenxTestEnv::test_data_directory_for_class('Tenx::Alignment') );
    $test{directory} = $test{data_dir}->subdir('succeeded');

};

subtest 'create' => sub{
    plan tests => 8;

    my $al = Tenx::Alignment->get(directory => $test{directory}->stringify);
    ok(!$al, 'alignment does not exist');

    my $cmd;
    lives_ok(
        sub{ $cmd = $test{pkg}->execute(
                directory => $test{directory}->stringify,
            ); },
        'execute',
    );
    ok($cmd->result, 'execute successful');

    $al = Tenx::Alignment->get(directory => $test{directory}->stringify);
    ok($al, 'alignment created');
    is($al->directory, $test{directory}->stringify, 'directory set');
    is($al->reads, $test{reads}, 'reads set');
    is($al->reference, $test{reference}, 'reference set');

    ok(UR::Context->commit, 'commit');

};

subtest 'create fails' => sub{
    plan tests => 3;

    throws_ok(
        sub{ $test{pkg}->execute(directory => $test{data_dir}->subdir('failed')->stringify); },
        qr/Cannot find "_invocation" file in/,
        'fails w/o _invocation file',
    );

    throws_ok(
        sub{ $test{pkg}->execute(directory => '/blah'); },
        qr/Directory \/blah does not exist/,
        'fails with invalid directory',
    );

    throws_ok(
        sub{ $test{pkg}->execute(directory => $test{directory}->stringify,
            ); },
        qr/Found existing alignment/,
        'fails when recreating',
    );

};

done_testing();
