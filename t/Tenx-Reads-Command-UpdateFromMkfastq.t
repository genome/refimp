#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

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

    $test{old_dir} = '/gscmnt/gc6144/techd/10x_Genomics_IDT_Exome_Reagent_Capture_HJNMJBBXX/HJNMJBBXX/';
    $test{reads} = [ map { RefImp::Reads->create(sample_name => $_, url => $test{old_dir}.'/outs/fastqs/'.$_) } (qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-3CTLA4-aCTLA4_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /)];
    is(@{$test{reads}}, 4, 'created reads');
    ok($test{reads}->[2]->url('/data/XXXXXA/outs/fastqs/'.$test{reads}->[2]->sample_name), 'change reads #3 url');
    $test{data_dir} = TestEnv::test_data_directory_for_class('RefImp::Reads');
    $test{mkfastq_directory} = $test{data_dir}->subdir('sample-sheet');

};

subtest 'update' => sub{
    plan tests => 7;

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
    like($err, qr/STATUS\s+SAMPLE\s+OLD\s+NEW\s+OK\s+M_FA/, 'correct output');
    like($err, qr/NOT_IN_DB\s+M_FA-3CTLA4-aCTLA4_10x/, 'skipped correct sample');

    my $mkfastq_dir = $test{mkfastq_directory}->stringify;
    my $update_cnt = grep { $_->url =~ /^$mkfastq_dir/ } @{$test{reads}};
    is($update_cnt, 3, 'updated 3 reads');
    is($test{reads}->[2]->url, '/data/XXXXXA/outs/fastqs/'.$test{reads}->[2]->sample_name, 'did not update read from different run');

    ok(UR::Context->commit, 'commit');

};

done_testing();
