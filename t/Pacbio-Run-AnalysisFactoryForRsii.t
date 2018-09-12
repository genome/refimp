#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Path::Class;
use Test::More tests => 3;
use Test::Exception;

my %setup = ( class => 'Pacbio::Run::AnalysisFactoryForRsii', );
subtest 'setup' => sub{
    plan tests => 3;

    use_ok($setup{class}) or die;

    $setup{run_dir} = TenxTestEnv::test_data_directory_for_class('Pacbio::Run')->subdir('6U00FA');
    ok(-d $setup{run_dir}->stringify, 'run data dir exists');

    my $subdir = $setup{run_dir}->subdir('A01_1')->subdir('Analysis_Results');
    my @afiles = map {
        $subdir->file( sprintf('m160819_231415_00116_c101036512550000001823251411171640_s1_p0.%d.bax.h5', $_) )
    } (qw/ 1 2 3 /);
    push @afiles, $subdir->file('m160819_231415_00116_c101036512550000001823251411171640_s1_p0.bas.h5');
    $setup{A01_1_analysis_files} = \@afiles;
    is(@{$setup{A01_1_analysis_files}}, 4, 'run analysis files');

};

subtest 'build' => sub{
    plan tests => 9;

    throws_ok(sub{ $setup{class}->build; }, qr/No run directory given/, 'fails w/o directory');
    throws_ok(sub{ $setup{class}->build('blah'); }, qr/Run directory given does not exist/, 'fails w/ non existing directory');

    my $analyses = $setup{class}->build($setup{run_dir});
    is(@$analyses, 10, 'built the correct number of analyses');
    is($analyses->[0]->metadata_xml_file, $setup{run_dir}->subdir('A01_1')->file('m160819_231415_00116_c101036512550000001823251411171640_s1_p0.metadata.xml'), 'metadata_xml_file');
    is($analyses->[0]->library_name, 'NA19434_4808o3_lib1_50pM_A1', 'library_name');
    is($analyses->[0]->plate_id, '6U00FA', 'plate_id');
    is($analyses->[0]->version, '2.3.0.3.154799', 'version');
    is($analyses->[0]->well, 'A01', 'well');
    is_deeply([sort @{$analyses->[0]->analysis_files}], [sort @{$setup{A01_1_analysis_files}}], 'analysis files');

};

subtest 'build from analysis directory' => sub{
    plan tests => 8;

    throws_ok(sub{ $setup{class}->build_from_analysis_directory; }, qr/No analysis directory given/, 'fails w/o directory');
    throws_ok(sub{ $setup{class}->build_from_analysis_directory('blah'); }, qr/Analysis directory given does not exist/, 'fails w/ non existing directory');
    throws_ok(sub{ $setup{class}->build_from_analysis_directory($setup{run_dir}->subdir('A01_1')->subdir('Analysis_Results')); }, qr/Failed to find analysis metadata xml in/, 'fails w/ when no analysis found');

    my $directory = $setup{run_dir}->subdir('A01_1');
    my $analysis = $setup{class}->build_from_analysis_directory($directory);
    is($analysis->metadata_xml_file, $directory->file('m160819_231415_00116_c101036512550000001823251411171640_s1_p0.metadata.xml'), 'metadata_xml_file');
    is($analysis->library_name, 'NA19434_4808o3_lib1_50pM_A1', 'library_name');
    is($analysis->plate_id, '6U00FA', 'plate_id');
    is($analysis->version, '2.3.0.3.154799', 'version');
    is($analysis->well, 'A01', 'well');

};

done_testing();
