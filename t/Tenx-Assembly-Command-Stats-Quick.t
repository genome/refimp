#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use File::Slurp 'slurp';
use Test::Exception;
use Test::More tests => 3;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    $test{class} = 'Tenx::Assembly::Command::Stats::Quick';
    use_ok($test{class});
    $test{data_dir} = TenxTestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}, 'data dir exists');


};

subtest 'success' => sub{
    plan tests => 3;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $test{class}->execute(fasta_file => $test{data_dir}->file('fasta')->stringify); }, 'execute'); 
    
    my $expected_output = slurp($test{data_dir}->file('fasta.stats')->stringify);
    ok($expected_output, 'loaded expected output');
    is($output, $expected_output, 'output matches');

};

subtest 'fails' => sub{
    plan tests => 1;

    throws_ok(sub{ $test{class}->execute(fasta_file => $test{data_dir}->stringify); }, qr/Fasta file does not exist/, 'execute fails w/ non existing fasta file'); 

};

done_testing();
