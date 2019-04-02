#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Compare;
use File::Temp;
use Path::Class;
use Test::Exception;
use Test::More tests => 2;

my %test = ( class => 'Sx::Command::Rename', );
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{class});
    $test{data_dir} = TestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}->stringify, 'data dir exists');
    $test{tempdir} = Path::Class::dir( File::Temp::tempdir(CLEANUP => 1) );

};

subtest 'execute' => sub{
    plan tests => 4;

    my $input = $test{data_dir}->file('input.fa')->stringify;
    my $output = $test{tempdir}->file('output.fa')->stringify;
    my $cmd = $test{class}->create(
        input => $input,
        output => $output,
        prepend => 'EXTRA-',
    );
    ok($cmd, 'create command');
    lives_ok(sub{ $cmd->execute }, 'execute');
    ok($cmd->result, 'command result');

    my $expected = $test{data_dir}->file('expected.fa')->stringify;
    is(File::Compare::compare($output, $expected), 0, 'output primary fasta matches');

};

done_testing();
