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
        pkg => 'Tenx::Reads::Command::CreateFromMkfastq',
        sample_name => 'TESTSAMPLE',
    );
    use_ok($test{pkg}) or die;

    $test{data_dir} = TestEnv::test_data_directory_for_class('RefImp::Reads');
    $test{mkfastq_directory} = $test{data_dir}->subdir('sample-sheet');
    $test{expected_sample_names} = [qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-3CTLA4-aCTLA4_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /];

};

subtest 'create' => sub{
    plan tests => 6;

    my @reads = RefImp::Reads->get(sample_name => $test{expected_sample_names});
    ok(!@reads, 'reads do not exist');

    my $err;
    open local(*STDERR), '>', \$err or die $!;
    my $cmd;
    lives_ok(
        sub{ $cmd = $test{pkg}->execute(
                directory => $test{mkfastq_directory}->stringify,
            ); },
        'execute',
    );
    ok($cmd->result, 'execute successful');
    like($err, qr/Created reads: M_FA-1CNTRL/, 'correct messages');

    @reads = RefImp::Reads->get(sample_name => $test{expected_sample_names});
    is_deeply([map { $_->sample_name } @reads], $test{expected_sample_names}, 'reads objects created');

    ok(UR::Context->commit, 'commit');

};

subtest 'fails' => sub{
    plan tests => 1;

    throws_ok(
        sub{ $test{pkg}->execute(directory => $test{mkfastq_directory}->stringify, targets_url => '/blah'); },
        qr/Given targets path does not exist:/,
        'fails w/ invalid targets_url',
    );

};

done_testing();
