#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 3;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    %test = (
        pkg => 'Tenx::Alignment::Command::CreateFromDirectory',
        sample_name => 'TESTSAMPLE',
        refseq => RefImp::Refseq->__define__(url => '/ref'),
        reads => RefImp::Reads->__define__(url => '/reads', sample_name => 'TEST'),
    );
    use_ok($test{pkg}) or die;

    $test{data_dir} = TestEnv::test_data_directory_for_class('RefImp::Alignment');
    $test{directory} = $test{data_dir}->subdir('succeeded');

};

subtest 'create' => sub{
    plan tests => 8;

    my $al = RefImp::Alignment->get(url => $test{directory}->stringify);
    ok(!$al, 'alignment does not exist');

    my $cmd;
    lives_ok(
        sub{ $cmd = $test{pkg}->execute(
                url => $test{directory}->stringify,
            ); },
        'execute',
    );
    ok($cmd->result, 'execute successful');

    $al = RefImp::Alignment->get(url => $test{directory}->stringify);
    ok($al, 'alignment created');
    is($al->url, $test{directory}->stringify, 'directory set');
    is($al->reads, $test{reads}, 'reads set');
    is($al->refseq, $test{refseq}, 'refseq set');

    ok(UR::Context->commit, 'commit');

};

subtest 'create fails' => sub{
    plan tests => 2;

    throws_ok(
        sub{ $test{pkg}->execute(url => $test{data_dir}->subdir('failed')->stringify); },
        qr/Cannot find "_invocation" file in/,
        'fails w/o _invocation file',
    );

    throws_ok(
        sub{ $test{pkg}->execute(url => $test{directory}->stringify,
            ); },
        qr/Found existing alignment/,
        'fails when recreating',
    );

};

done_testing();
