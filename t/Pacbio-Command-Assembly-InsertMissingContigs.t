#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use File::Compare;
use File::Slurp;
use File::Temp;
use Path::Class;
use Test::Exception;
use Test::More tests => 3;

my %test = ( class => 'Pacbio::Command::Assembly::InsertMissingContigs', );
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{class});
    $test{data_dir} = TenxTestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}->stringify, 'data dir exists');
    $test{tempdir} = Path::Class::dir( File::Temp::tempdir(CLEANUP => 1) );

};

subtest 'execute' => sub{
    plan tests => 7;

    my $got_primary = $test{tempdir}->file('p.got.fasta')->stringify;
    my $got_haplotigs = $test{tempdir}->file('h.got.fasta')->stringify;
    my $cmd = $test{class}->create(
        primary_fasta => $test{data_dir}->file('p_ctg.fasta')->stringify,
        haplotigs_fasta => $test{data_dir}->file('h_ctg.fasta')->stringify,
        output_primary_fasta => $got_primary,
        output_haplotigs_fasta => $got_haplotigs,
    );
    ok($cmd, 'create command');
    lives_ok(sub{ $cmd->execute }, 'execute');
    ok($cmd->result, 'command result');

    my $expected_primary = $test{data_dir}->file('p.expected.fasta')->stringify;
    is(File::Compare::compare($got_primary, $expected_primary), 0, 'output primary fasta matches');
    my $expected_haplotigs = $test{data_dir}->file('h.expected.fasta')->stringify;
    is(File::Compare::compare($got_haplotigs, $expected_haplotigs), 0, 'output haplotigs fasta matches');

    is($cmd->primary_fai, $cmd->primary_fasta.'.fai', 'set primary fai');
    is($cmd->haplotigs_fai, $cmd->haplotigs_fasta.'.fai', 'set haplotigs fai');

};

subtest 'haplotig id tokens' => sub{
    plan tests => 3;

    throws_ok(sub{ $test{class}->haplotig_id_tokens(); } , qr/No haplotig id/, 'fails w/o haplotig id');
    throws_ok(sub{ $test{class}->haplotig_id_tokens('000200F|arrow'); } , qr/Could not find haplotig number/, 'fails w/o invalid haplotig id');
    my @expected = (qw/ 000200F 002 |arrow /);
    is_deeply($test{class}->haplotig_id_tokens('000200F_002|arrow'), \@expected, 'correct primary id');

};

done_testing();
