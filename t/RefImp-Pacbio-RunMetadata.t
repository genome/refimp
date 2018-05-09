#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::More tests => 1;
use Test::Exception;

my %setup = ( class => 'RefImp::Pacbio::RunMetadata', );
subtest 'new' => sub{
    plan tests => 6;

    use_ok($setup{class}) or die;

    throws_ok(sub{ $setup{class}->new; }, qr/No metadata XML file given/, 'new fails w/o xml_file');
    throws_ok(sub{ $setup{class}->new(xml_file => file('blah')); }, qr/Metadata XML file does not exist/, 'new fails w/ non existing xml_file');

    my $xml_file = dir( TestEnv::test_data_directory_for_package('RefImp::Pacbio::Run') )->subdir('6U00FA')->subdir('A01_1')->file('m160819_231415_00116_c101036512550000001823251411171640_s1_p0.metadata.xml');
    ok(-f "$xml_file", "example metadata xml file exists");

    my $run = $setup{class}->new($xml_file);
    ok($run, 'create run');
    ok($run->xml_file, 'xml_file');

    $setup{run} = $run;

};

done_testing();
