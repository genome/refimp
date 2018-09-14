#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Test::More tests => 3;

my %test = ( class => 'Pacbio::Run::Analysis', );
subtest 'new' => sub{
    plan tests => 8;

    use_ok($test{class}) or die;

    my %params = (
        metadata_xml_file => 'xml', library_name => 'LIBRARY',
        plate_id => 'PLATE', version => 'VERSION', well => 'WELL', analysis_files => [],
    );
    my $meta = $test{class}->new(%params);
    ok($meta, 'create run');
    $test{meta} = $meta;

    ok($meta->metadata_xml_file, 'xml_file');
    ok($meta->library_name, 'library_name');
    ok($meta->plate_id, 'plate_id');
    ok($meta->version, 'version');
    ok($meta->well, 'well');
    ok($meta->analysis_files, 'analysis_files');

};

subtest 'add_analysis_files' => sub{
    plan tests => 3;

    my $meta = $test{meta};
    is_deeply($meta->analysis_files, [], 'no analysis_files');
    ok($meta->add_analysis_files('FILE'), 'add_analysis_files');
    is_deeply($meta->analysis_files, ['FILE'], 'correct analysis_files');

};

subtest 'name and alias' => sub{
    plan tests => 2;

    is($test{meta}->__name__, 'PLATE WELL LIBRARY', 'correct __name__');
    is($test{meta}->alias, 'PLATE_WELL', 'correct alias');

};

done_testing();
