#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::More tests => 1;
use Test::Exception;

my %setup = ( class => 'RefImp::Pacbio::Run::AnalysisFactory', );
subtest 'new' => sub{
    plan tests => 11;

    use_ok($setup{class}) or die;

    throws_ok(sub{ $setup{class}->build; }, qr/No metadata XML file given/, 'new fails w/o xml_file');
    throws_ok(sub{ $setup{class}->build(xml_file => file('blah')); }, qr/Metadata XML file does not exist/, 'new fails w/ non existing xml_file');

    my $xml_file = dir( TestEnv::test_data_directory_for_package('RefImp::Pacbio::Run') )->subdir('6U00FA')->subdir('A01_1')->file('m160819_231415_00116_c101036512550000001823251411171640_s1_p0.metadata.xml');
    ok(-f "$xml_file", "example metadata xml file exists");

    my $meta = $setup{class}->build($xml_file);
    ok($meta, 'create run');
    is($meta->metadata_xml_file->stringify, "$xml_file", 'metadata_xml_file');
    is($meta->sample_name, 'NA19434_4808o3_lib1_50pM', 'sample_name');
    is($meta->library_name, 'NA19434_4808o3_lib1_50pM_A1', 'library_name');
    is($meta->plate_id, '6U00FA', 'plate_id');
    is($meta->version, '2.3.0.3.154799', 'version');
    is($meta->well, 'A01', 'well');

    $setup{meta} = $meta;

};

done_testing();
