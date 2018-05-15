#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::More tests => 1;
use Test::Exception;

my %setup = ( class => 'RefImp::Pacbio::Run::AnalysisFactoryForSequel', );
subtest 'new' => sub{
    plan tests => 12;

    use_ok($setup{class}) or die;

    throws_ok(sub{ $setup{class}->build; }, qr/No run directory given/, 'new fails w/o directory');
    throws_ok(sub{ $setup{class}->build('blah'); }, qr/Run directory given does not exist/, 'new fails w/ non existing directory');

    my $run_id= '6U00I7';
    my $directory = dir( TestEnv::test_data_directory_for_package('RefImp::Pacbio::Run') )->subdir($run_id);
    ok(-d "$directory", "example run directory exists");

    my $analyses = $setup{class}->build($directory);
    is(@$analyses, 5, 'built the correct number of analyses');
    is($analyses->[0]->metadata_xml_file, $directory->subdir('1_A01')->file('.m54111_170804_145334.metadata.xml'), 'metadata_xml_file');
    is($analyses->[0]->sample_name, 'HG03486_Mende_4808Ll', 'sample_name');
    is($analyses->[0]->library_name, 'HG03486_Mende_4808Ll_20pM', 'library_name');
    is($analyses->[0]->plate_id, $run_id, 'plate_id');
    is($analyses->[0]->version, '4.0.0.189873', 'version');
    is($analyses->[0]->well, 'A01', 'well');
    is_deeply($analyses->[0]->analysis_files, [ $directory->subdir('1_A01')->file('m54111_170804_145334.subreads.bam') ], 'analysis_files');

};

done_testing();
