#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 5;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    $test{pkg} = 'RefImp::Tenx::SampleSheet';
    use_ok($test{pkg}) or die;

    $test{data_dir} = dir( TestEnv::test_data_directory_for_package($test{pkg}) );

};

subtest "load_from_file fails" => sub{
    plan tests => 6;

    throws_ok(sub{ $test{pkg}->load_from_file(); }, qr/No sample sheet file given/, 'load_from_file fails w/o file');
    throws_ok(sub{ $test{pkg}->load_from_file('/blah'); }, qr/Sample sheet file given does not exist/, 'load_from_file fails w/ non existing file');

    throws_ok(sub{ $test{pkg}->load_from_file( $test{data_dir}->file('no-sample-header.csv') ); }, qr/No sample column found in/, 'load_from_file fails w/o sample column');

    throws_ok(sub{ $test{pkg}->load_from_file( $test{data_dir}->file('no-index.csv') ); }, qr/No index found/, 'load_from_file fails w/o index');
    throws_ok(sub{ $test{pkg}->load_from_file( $test{data_dir}->file('no-sample.csv') ); }, qr/No sample name found/, 'load_from_file fails w/o sample');
    throws_ok(sub{ $test{pkg}->load_from_file( $test{data_dir}->file('no-lane.csv') ); }, qr/No lane found/, 'load_from_file fails w/o lane');


};

subtest "load_from_file simple csv" => sub{
    plan tests => 1;

    my $ss = $test{pkg}->load_from_file( $test{data_dir}->file('simple.csv') );
    ok($ss, 'load_from_file');

};

subtest "load_from_file sample sheet csv" => sub{
    plan tests => 1;

    my $ss = $test{pkg}->load_from_file( $test{data_dir}->file('sample-sheet.csv') );
    ok($ss, 'load_from_file');
    $test{ss} = $ss;

};

subtest "properties" => sub{
    plan tests => 2;

    is_deeply([$test{ss}->lanes], [1,2], 'lanes');

    my @expected_sample_names = sort (qw/ M_EO-Fresh_Marrow-WT_Fresh_WBM_01252017_10x M_EO-cryo_marrow-WT_Frozen_WBM_01252017_10x M_EO-Kit_positive_marrow-WT_Fresh_c-KIT_01252017_10x M_EO-kit_positive_cryo_marrow-WT_Frozen_c-KIT_01252017_10x /);
    is_deeply([$test{ss}->sample_names], \@expected_sample_names, 'sample_names');

};

done_testing();
