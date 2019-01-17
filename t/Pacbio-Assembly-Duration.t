#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;
use Test::More tests => 2;

my %test = ( class => 'Pacbio::Assembly::Duration');
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{class}) or die;
    $test{data_dir} = TestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}, 'data dir exists');

};

subtest 'blocking' => sub{
    plan tests => 3;

    my $dir = $test{data_dir}->subdir('blocking');
    ok(-d $dir, 'blocking data dir exists');

    my $duration = $test{class}->new($dir);
    ok($duration, 'create duration');

    my %expected_stages = (
        '0-rawreads' => '809.626',
        '0-rawreads daligner-runs' => '809.626',
        '1-preads_ovl' => '381.421',
        '1-preads_ovl daligner-split' => '0.426',
        '1-preads_ovl daligner-combine' => '0.362',
        '1-preads_ovl daligner-gathered' => '0.316',
        '1-preads_ovl daligner-runs' => '377.906',
        '1-preads_ovl daligner-chunks' => '2.411',
        '2-asm-falcon' => '86.993',
    );

    my $stages = $duration->get_stages;
    is_deeply($stages, \%expected_stages, 'got stages');

};

done_testing();
