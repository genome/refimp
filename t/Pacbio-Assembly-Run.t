#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;
use Test::More tests => 3;

my %test = ( class => 'Pacbio::Assembly::Run');
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

subtest 'fs_based' => sub{
    plan tests => 3;

    my $dir = $test{data_dir}->subdir('fs_based');
    ok(-d $dir, 'fs_based data dir exists');

    my $duration = $test{class}->new($dir);
    ok($duration, 'create duration');

	my %expected_stages = (
		'0-rawreads' => '865.437',
		'0-rawreads daligner-runs' => '865.437',
		'1-preads_ovl' => '399.28',
		'1-preads_ovl daligner-combine' => '0.343',
		'1-preads_ovl daligner-chunks' => '1.905',
		'1-preads_ovl daligner-gathered' => '0.451',
		'1-preads_ovl daligner-runs' => '396.219',
		'1-preads_ovl daligner-split' => '0.362',
		'2-asm-falcon' => '115.335',
        '3-unzip' => '2961.471',
        '3-unzip 0-phasing' => '8.187',
        '3-unzip 0-phasing phasing-chunks' => '8.187',
        '3-unzip 2-htigs' => '2953.284',
        '3-unzip 2-htigs chunks' => '0.523',
        '4-polish' => '281.194',
        '4-polish segregate-chunks' => '0.519',
        '4-polish quiver-chunks' => '0.729',
        '4-polish quiver-run' => '279.946',
	);

    my $stages = $duration->get_stages;
    is_deeply($stages, \%expected_stages, 'got stages');

};

done_testing();
