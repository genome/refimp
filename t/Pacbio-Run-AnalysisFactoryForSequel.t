#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Path::Class;
use Test::More tests => 3;
use Test::Exception;

my %test = ( class => 'Pacbio::Run::AnalysisFactoryForSequel', );
subtest 'setup and fails' => sub{
    plan tests => 3;

    use_ok($test{class}) or die;

    throws_ok(sub{ $test{class}->build; }, qr/No run directory given/, 'new fails w/o directory');
    throws_ok(sub{ $test{class}->build('blah'); }, qr/Run directory given does not exist/, 'new fails w/ non existing directory');
};

subtest 'new version 4.0.0' => sub{
    plan tests => 8;

    my $run_id= '6U00I7';
    my $directory = dir( TenxTestEnv::test_data_directory_for_class('Pacbio::Run') )->subdir($run_id);
    ok(-d "$directory", "example run directory exists");

    my $analyses = $test{class}->build($directory);
    is(@$analyses, 5, 'built the correct number of analyses');
    is($analyses->[0]->metadata_xml_file, $directory->subdir('1_A01')->file('.m54111_170804_145334.metadata.xml'), 'metadata_xml_file');
    is($analyses->[0]->library_name, 'HG03486_Mende_4808Ll_20pM', 'library_name');
    is($analyses->[0]->plate_id, $run_id, 'plate_id');
    is($analyses->[0]->version, '4.0.0.189873', 'version');
    is($analyses->[0]->well, 'A01', 'well');
    is_deeply($analyses->[0]->analysis_files, [ $directory->subdir('1_A01')->file('m54111_170804_145334.subreads.bam') ], 'analysis_files');

};

subtest 'new version 4.0.1' => sub{
    plan tests => 8;

    my $run_id= '6U00IG';
    my $directory = dir( TenxTestEnv::test_data_directory_for_class('Pacbio::Run') )->subdir($run_id);
    ok(-d "$directory", "example run directory exists");

    my $analyses = $test{class}->build($directory);
    is(@$analyses, 2, 'built the correct number of analyses');
    is($analyses->[1]->metadata_xml_file, $directory->subdir('2_B01')->file('.m54111_170830_013202.metadata.xml'), 'metadata_xml_file');
    is($analyses->[1]->library_name, 'X.couchianus_4808Lu_18pM', 'library_name');
    is($analyses->[1]->plate_id, $run_id, 'plate_id');
    is($analyses->[1]->version, '5.0.0.6235', 'version');
    is($analyses->[1]->well, 'B01', 'well');
    is_deeply($analyses->[1]->analysis_files, [ $directory->subdir('2_B01')->file('m54111_170830_013202.subreads.bam') ], 'analysis_files');

};

done_testing();
