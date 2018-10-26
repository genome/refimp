#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;

use Path::Class;
use Sub::Install;
use Test::Exception;
use Test::More tests => 2;

my %test;
subtest 'setup' => sub{
    plan tests => 3;

    %test = (
        pkg => 'Tenx::Reads::Command::UpdateFromMkfastq',
    );
    use_ok($test{pkg}) or die;

    $test{old_dir} = '/data/XXXXXX';
    $test{reads} = [ map { Tenx::Reads->create(sample_name => $_, directory => $test{old_dir}.'/outs/fastqs/'.$_) } (qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-3CTLA4-aCTLA4_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /)];
    is(@{$test{reads}}, 4, 'created reads');
    ok($test{reads}->[2]->directory('/data/XXXXXA/outs/fastqs/'.$test{reads}->[2]->sample_name), 'change reads #3 directory');
    $test{data_dir} = dir( TenxTestEnv::test_data_directory_for_class('Tenx::Reads') );
    $test{mkfastq_directory} = $test{data_dir}->subdir('sample-sheet');

};

subtest 'update' => sub{
    plan tests => 7;

    my $err;
    open local(*STDERR), '>', \$err or die $!;
    my $cmd;
    lives_ok(
        sub{ $cmd = $test{pkg}->execute(
                old_directory => $test{old_dir},
                directory => $test{mkfastq_directory}->stringify,
            ); },
        'execute',
    );
    ok($cmd->result, 'execute successful');
    like($err, qr/STATUS\s+SAMPLE\s+OLD\s+NEW\s+OK\s+M_FA/, 'correct output');
    like($err, qr/NOT_IN_DB\s+M_FA-3CTLA4-aCTLA4_10x/, 'skipped correct sample');

    my $mkfastq_dir = $test{mkfastq_directory}->stringify;
    my $update_cnt = grep { $_->directory =~ /^$mkfastq_dir/ } @{$test{reads}};
    is($update_cnt, 3, 'updated 3 reads');
    is($test{reads}->[2]->directory, '/data/XXXXXA/outs/fastqs/'.$test{reads}->[2]->sample_name, 'did not update read from different run');

    ok(UR::Context->commit, 'commit');

};

done_testing();
