#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::More tests => 1;

my %test = ( class => 'RefImp::Pacbio::RunMeta', );
subtest 'new' => sub{
    plan tests => 6;

    use_ok($test{class}) or die;

    my %params = ( metadata_xml_file => 'xml', sample_name => 'sample', well => 'well', analysis_files => [],);
    my $meta = $test{class}->new(%params);
    ok($meta, 'create run');
    ok($meta->metadata_xml_file, 'xml_file');
    ok($meta->sample_name, 'sample_name');
    ok($meta->well, 'well');
    ok($meta->analysis_files, 'analysis_files');

};

done_testing();
