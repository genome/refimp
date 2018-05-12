#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::More tests => 1;
use Test::Exception;

my %setup = ( class => 'RefImp::Pacbio::Run::AnalysisFactoryForRsii', );
subtest 'new' => sub{
    plan tests => 11;

    use_ok($setup{class}) or die;

    throws_ok(sub{ $setup{class}->build; }, qr/No run directory given/, 'new fails w/o directory');
    throws_ok(sub{ $setup{class}->build('blah'); }, qr/Run directory given does not exist/, 'new fails w/ non existing directory');

    my $directory = dir( TestEnv::test_data_directory_for_package('RefImp::Pacbio::Run') )->subdir('6U00FA');
    ok(-d "$directory", "example run directory exists");

    my $analyses = $setup{class}->build($directory);
    is(@$analyses, 10, 'built the correct number of analyses');
    is($analyses->[0]->metadata_xml_file, $directory->subdir('A01_1')->file('m160819_231415_00116_c101036512550000001823251411171640_s1_p0.metadata.xml'), 'metadata_xml_file');
    is($analyses->[0]->sample_name, 'NA19434_4808o3_lib1_50pM', 'sample_name');
    is($analyses->[0]->library_name, 'NA19434_4808o3_lib1_50pM_A1', 'library_name');
    is($analyses->[0]->plate_id, '6U00FA', 'plate_id');
    is($analyses->[0]->version, '2.3.0.3.154799', 'version');
    is($analyses->[0]->well, 'A01', 'well');

};

done_testing();
