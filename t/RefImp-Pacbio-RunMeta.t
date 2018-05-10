#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::More tests => 2;

my %test = ( class => 'RefImp::Pacbio::RunMeta', );
subtest 'new' => sub{
    plan tests => 6;

    use_ok($test{class}) or die;

    my %params = ( metadata_xml_file => 'xml', sample_name => 'sample', well => 'well', analysis_files => [],);
    my $meta = $test{class}->new(%params);
    ok($meta, 'create run');
    $test{meta} = $meta;

    ok($meta->metadata_xml_file, 'xml_file');
    ok($meta->sample_name, 'sample_name');
    ok($meta->well, 'well');
    ok($meta->analysis_files, 'analysis_files');

};

subtest 'add_analysis_file' => sub{
    plan tests => 3;

    my $meta = $test{meta};
    is_deeply($meta->analysis_files, [], 'no analysis_files');
    ok($meta->add_analysis_file('FILE'), 'add_analysis_file');
    is_deeply($meta->analysis_files, ['FILE'], 'correct analysis_files');

};

done_testing();
