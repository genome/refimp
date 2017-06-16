#!/usr/bin/env perl5.10.1

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
        pkg => 'RefImp::Tenx::Command::Alignment::Create',
        sample_name => 'TESTSAMPLE',
        reference => RefImp::Tenx::Reference->__define__(directory => '/tmp'),
        reads => RefImp::Tenx::Reads->__define__(directory => '/tmp', sample_name => 'TEST'),
    );
    use_ok($test{pkg}) or die;


    $test{data_dir} = dir( TestEnv::test_data_directory_for_package('RefImp::Tenx::Alignment') );
    $test{directory} = $test{data_dir}->subdir('succeeded');

};

subtest 'create' => sub{
    plan tests => 8;

    my $al = RefImp::Tenx::Alignment->get(directory => $test{directory}->stringify);
    ok(!$al, 'alignment does not exist');

    my $cmd;
    lives_ok(
        sub{ $cmd = $test{pkg}->execute(
                directory => $test{directory}->stringify,
                reads => $test{reads},
                reference => $test{reference},
            ); },
        'execute',
    );
    ok($cmd->result, 'execute successful');

    $al = RefImp::Tenx::Alignment->get(directory => $test{directory}->stringify);
    ok($al, 'alignment created');
    is($al->directory, $test{directory}->stringify, 'directory set');
    is($al->reads, $test{reads}, 'reads set');
    is($al->reference, $test{reference}, 'reference set');

    ok(UR::Context->commit, 'commit');

};

subtest 'create fails' => sub{
    plan tests => 2;

    throws_ok(
        sub{ $test{pkg}->execute(
                directory => $test{directory}->stringify,
                reads => $test{reads},
                reference => $test{reference},
            ); },
        qr/Found existing alignment/,
        'fails when recreating',
    );

    throws_ok(
        sub{ $test{pkg}->execute(
                directory => '/blah',
                reads => $test{reads},
                reference => $test{reference},
            ); },
        qr/Directory \/blah does not exist/,
        'fails with invalid directory',
    );

};

done_testing();
