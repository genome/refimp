#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Compare 'compare';
use File::Temp 'tempdir';
use Test::Exception;
use Test::More tests => 5;

my %setup;
subtest 'setup' => sub {
    plan tests => 2;

    $setup{pkg} = 'RefImp::Assembly::Command::Submission::SplitFasta';
    use_ok($setup{pkg}) or die;

    $setup{data_dir} = TestEnv::test_data_directory_for_package($setup{pkg});
    $setup{fasta_file} = File::Spec->join($setup{data_dir}, 'input.fasta');
    ok(-s $setup{fasta_file}, 'fasta file exists');
    $setup{tempdir} = tempdir(CLEANUP => 1);
    $setup{output_fasta_file_pattern} = File::Spec->join(tempdir(CLEANUP => 1), 'contigs.%s.fsa');

};

subtest 'split, but not really' => sub {
    plan tests => 4;

    my $cmd;
    my $output_fasta_file_pattern = File::Spec->join($setup{tempdir}, 'contigs.not-really.%s.fsa');
    lives_ok(
        sub{ $cmd =$setup{pkg}->execute(fasta_file => $setup{fasta_file}, output_fasta_file_pattern => $output_fasta_file_pattern, max_seq_count => 10); },
        'execute',
    );
    ok($cmd->result, 'result');

    my @output_fasta_files = $cmd->output_fasta_files;
    is(@output_fasta_files, 1, 'output_fasta_files count');

    my $expected_fasta_file = $setup{fasta_file};
    is( compare($output_fasta_files[0], $expected_fasta_file), 0, 'output fasta files match');

};

subtest 'split by count' => sub{
    plan tests => 5;

    my $cmd;
    my $output_fasta_file_pattern = File::Spec->join($setup{tempdir}, 'contigs.by-count.%s.fsa');
    lives_ok(
        sub{ $cmd =$setup{pkg}->execute(fasta_file => $setup{fasta_file}, output_fasta_file_pattern => $output_fasta_file_pattern, max_seq_count => 2); },
        'execute',
    );
    ok($cmd->result, 'result');

    my @output_fasta_files = $cmd->output_fasta_files;
    is(@output_fasta_files, 2, 'output_fasta_files count');

    my $expected_fasta_file = $setup{fasta_file};
    for (1..@output_fasta_files) {
        is(compare($output_fasta_files[$_ - 1], File::Spec->join($setup{data_dir}, "expected.split-by-count.$_.fasta")), 0, "output fasta $_ file matches");
    }

};

subtest 'split by size' => sub{
    plan tests => 7;

    my $cmd;
    my $output_fasta_file_pattern = File::Spec->join($setup{tempdir}, 'contigs.by-size.%s.fsa');
    lives_ok(
        sub{ $cmd =$setup{pkg}->execute(fasta_file => $setup{fasta_file}, output_fasta_file_pattern => $output_fasta_file_pattern, max_file_size => 118); },
        'execute',
    );
    ok($cmd->result, 'result');

    my @output_fasta_files = $cmd->output_fasta_files;
    is(@output_fasta_files, 4, 'output_fasta_files count');

    my $expected_fasta_file = $setup{fasta_file};
    for (1..@output_fasta_files) {
        is(compare($output_fasta_files[$_ - 1], File::Spec->join($setup{data_dir}, "expected.split-by-size.$_.fasta")), 0, "output fasta $_ file matches");
    }

};

subtest 'fails' => sub{
    plan tests => 5;

    throws_ok(sub{ $setup{pkg}->execute(fasta_file => '/blah', max_seq_count => 1); }, qr/Fasta file does not exist/, 'fails w/ non existing fasta file');
    throws_ok(sub{ $setup{pkg}->execute(fasta_file => $setup{fasta_file}, output_fasta_file_pattern => '/blah', max_seq_count => 1); }, qr/Invalid output fasta file pattern/, 'fails w/ invalid pattern');
    throws_ok(sub{ $setup{pkg}->execute(fasta_file => $setup{fasta_file}, output_fasta_file_pattern => '/blah/%s', max_seq_count => 1); }, qr/Output directory does not exist/, 'fails w/ invalid directory');

    my $output_fasta_file_pattern = File::Spec->join($setup{tempdir}, 'contigs.fails.%s.fsa');
    throws_ok(sub{ $setup{pkg}->execute(fasta_file => $setup{fasta_file}, output_fasta_file_pattern => $output_fasta_file_pattern); }, qr/No max_seq_count or max_file_size set/, 'fails w/o max_seq_count or max_file_size');
    throws_ok(sub{ $setup{pkg}->execute(fasta_file => $setup{fasta_file}, output_fasta_file_pattern => $output_fasta_file_pattern, max_file_size => 1); }, qr/Max file size \(1\) prevents/, 'fails with too small max_file_size');

};

done_testing();
