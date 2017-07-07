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

subtest "create_from_mkfastq_directory fails" => sub{
    plan tests => 7;

    throws_ok(sub{ $test{pkg}->create_from_mkfastq_directory(); }, qr/No mkfastq directory given/, 'create_from_mkfastq_directory fails w/o file');
    throws_ok(sub{ $test{pkg}->create_from_mkfastq_directory('/blah'); }, qr/Mkfastq directory given does not exist/, 'create_from_mkfastq_directory fails w/ non existing file');
    throws_ok(sub{ $test{pkg}->create_from_mkfastq_directory('/tmp'); }, qr/No samplesheet found in mkfastq/, 'create_from_mkfastq_directory fails w/ non existing file');

    throws_ok(sub{ $test{pkg}->create_from_mkfastq_directory( $test{data_dir}->subdir('no-sample-header') ); }, qr/No sample column found in/, 'create_from_mkfastq_directory fails w/o sample column');

    throws_ok(sub{ $test{pkg}->create_from_mkfastq_directory( $test{data_dir}->subdir('no-index') ); }, qr/No index found/, 'create_from_mkfastq_directory fails w/o index');
    throws_ok(sub{ $test{pkg}->create_from_mkfastq_directory( $test{data_dir}->subdir('no-sample') ); }, qr/No sample name found/, 'create_from_mkfastq_directory fails w/o sample');
    throws_ok(sub{ $test{pkg}->create_from_mkfastq_directory( $test{data_dir}->subdir('no-lane') ); }, qr/No lane found/, 'create_from_mkfastq_directory fails w/o lane');


};

subtest "create_from_mkfastq_directory simple csv" => sub{
    plan tests => 1;

    my $ss = $test{pkg}->create_from_mkfastq_directory( $test{data_dir}->subdir('simple') );
    ok($ss, 'create_from_mkfastq_directory');

};

subtest "create_from_mkfastq_directory sample sheet csv" => sub{
    plan tests => 1;

    my $ss = $test{pkg}->create_from_mkfastq_directory( $test{data_dir}->subdir('sample-sheet') );
    ok($ss, 'create_from_mkfastq_directory');
    $test{ss} = $ss;

};

subtest "properties" => sub{
    plan tests => 3;

    is_deeply([$test{ss}->lanes], [1,2,3,4,5,6,8], 'lanes');

    my @expected_sample_names = sort (qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-3CTLA4-aCTLA4_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /);
    is_deeply([$test{ss}->sample_names], \@expected_sample_names, 'sample_names');
    is_deeply($test{ss}->project_name, 'CA3MYANXX', 'project_name');

};

done_testing();
