#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::More tests => 1;
use Test::Exception;

my %setup = ( class => 'RefImp::Pacbio::RunMetadataFactory', );
subtest 'new' => sub{
    plan tests => 8;

    use_ok($setup{class}) or die;
    use_ok('RefImp::Pacbio::RunMeta') or die;

    throws_ok(sub{ $setup{class}->build; }, qr/No metadata XML file given/, 'new fails w/o xml_file');
    throws_ok(sub{ $setup{class}->build(xml_file => file('blah')); }, qr/Metadata XML file does not exist/, 'new fails w/ non existing xml_file');

    my $xml_file = dir( TestEnv::test_data_directory_for_package('RefImp::Pacbio::Run') )->subdir('6U00FA')->subdir('A01_1')->file('m160819_231415_00116_c101036512550000001823251411171640_s1_p0.metadata.xml');
    ok(-f "$xml_file", "example metadata xml file exists");

    my $meta = $setup{class}->build($xml_file);
    ok($meta, 'create run');
    ok($meta->metadata_xml_file, 'metadata_xml_file');
    ok($meta->sample_name, '');

    $setup{meta} = $meta;

};

done_testing();
