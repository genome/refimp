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

    $test{pkg} = 'Tenx::Reads::MkfastqRun';
    use_ok($test{pkg}) or die;

    $test{data_dir} = dir( TenxTestEnv::test_data_directory_for_class('Tenx::Reads') );
    $test{expected_sample_names} = [qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-3CTLA4-aCTLA4_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /];

};

subtest "create fails" => sub{
    plan tests => 3;

    throws_ok(sub{ $test{pkg}->create(); }, qr/but 2 were expected/, 'create fails w/o dir');
    throws_ok(sub{ $test{pkg}->create('/blah'); }, qr/Mkfastq directory given does not exist/, 'create fails w/ non existing dir');
    throws_ok(sub{ $test{pkg}->create('/tmp'); }, qr/No samplesheet found in mkfastq/, 'create fails w/o sample she');

};

subtest "create" => sub{
    plan tests => 1;

    my $ss = $test{pkg}->create( $test{data_dir}->subdir('sample-sheet') );
    ok($ss, 'create');
    $test{ss} = $ss;

};

subtest "properties" => sub{
    plan tests => 3;

    is_deeply([$test{ss}->lanes], [1,2,3,4,5,6,8], 'lanes');
    is_deeply([$test{ss}->sample_names], $test{expected_sample_names}, 'sample_names');
    is_deeply($test{ss}->project_name, 'CA3MYANXX', 'project_name');

};

subtest "fastq_directory_for_sample_name" => sub{
    plan tests => 6;

    my $ss = $test{ss};
    throws_ok(sub{ $ss->fastq_directory_for_sample_name; }, qr/but 2 were expected/, 'fails without sample name');

    my $sample_name = $test{expected_sample_names}[0];
    is(
        $ss->fastq_directory_for_sample_name($sample_name),
        $ss->directory->subdir($ss->project_name)->subdir($sample_name),
        "fastq directory for $sample_name",
    );

    $sample_name = $test{expected_sample_names}[1];
    is(
        $ss->fastq_directory_for_sample_name($sample_name),
        $ss->directory->subdir('MM')->subdir($sample_name),
        "fastq directory for $sample_name",
    );

    $sample_name = $test{expected_sample_names}[2];
    is(
        $ss->fastq_directory_for_sample_name($sample_name),
        $ss->directory->subdir($sample_name),
        "fastq directory for $sample_name",
    );

    $sample_name = $test{expected_sample_names}[3];
    is(
        $ss->fastq_directory_for_sample_name($sample_name),
        $ss->directory->subdir('outs')->subdir('fastq_path')->subdir('MM')->subdir($sample_name),
        "fastq directory for $sample_name",
    );

    $sample_name = 'BLAH';
    throws_ok(
        sub{ $ss->fastq_directory_for_sample_name($sample_name); },
        qr/Could not find fastqs for sample: $sample_name/,
        "no fastq directory for $sample_name",
    );

};

done_testing();
