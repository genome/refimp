#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 5;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    $test{pkg} = 'Tenx::Reads::SampleSheet';
    use_ok($test{pkg}) or die;

    $test{data_dir} = dir( TenxTestEnv::test_data_directory_for_class('Tenx::Reads') );
    $test{expected_sample_names} = [qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-3CTLA4-aCTLA4_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /];

};

subtest "create fails" => sub{
    plan tests => 6;

    throws_ok(sub{ $test{pkg}->create(); }, qr/but 2 were expected/, 'create fails w/o file');
    throws_ok(sub{ $test{pkg}->create('/blah'); }, qr/Samplesheet file given does not exist/, 'fails w/ non existing file');

    throws_ok(sub{ $test{pkg}->create( $test{data_dir}->subdir('no-sample-header', 'outs')->file('input_samplesheet.csv') ); }, qr/No sample column found in/, 'create fails w/o sample column');
    throws_ok(sub{ $test{pkg}->create( $test{data_dir}->subdir('no-index', 'outs',)->file('input_samplesheet.csv') ); }, qr/No index found/, 'create fails w/o index');
    throws_ok(sub{ $test{pkg}->create( $test{data_dir}->subdir('no-sample', 'outs')->file('input_samplesheet.csv') ); }, qr/No sample name found/, 'create fails w/o sample');
    throws_ok(sub{ $test{pkg}->create( $test{data_dir}->subdir('no-lane', 'outs')->file('input_samplesheet.csv') ); }, qr/No lane found/, 'create fails w/o lane');


};

subtest "create simple csv" => sub{
    plan tests => 1;

    my $ss = $test{pkg}->create( $test{data_dir}->subdir('simple', 'outs')->file('input_samplesheet.csv') );
    ok($ss, 'create');

};

subtest "create sample sheet csv" => sub{
    plan tests => 1;

    my $ss = $test{pkg}->create( $test{data_dir}->subdir('sample-sheet', 'outs')->file('input_samplesheet.csv') );
    ok($ss, 'create');
    $test{ss} = $ss;

};

subtest "properties" => sub{
    plan tests => 2;

    is_deeply([$test{ss}->lanes], [1,2,3,4,5,6,8], 'lanes');
    is_deeply([$test{ss}->sample_names], $test{expected_sample_names}, 'sample_names');

};

done_testing();
