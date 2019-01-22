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

    my $run = $test{class}->new($dir);
    ok($run, 'create run');

    my $expected_stages = {
		'0-rawreads' => {
			'duration' => '809.626',
			'substages' => {
				'daligner-runs' => '809.626',
			},
		},
		'1-preads_ovl' => {
			'substages' => {
				'daligner-chunks' => '2.411',
				'daligner-runs' => '377.906',
				'daligner-combine' => '0.362',
				'daligner-split' => '0.426',
				'daligner-gathered' => '0.316',
			},
			'duration' => '381.421',
		},
		'2-asm-falcon' => {
			'duration' => '86.993',
		},
	};

	my $stages = $run->get_stages;
    is_deeply($stages, $expected_stages, 'got stages');

};

subtest 'fs_based' => sub{
    plan tests => 3;

    my $dir = $test{data_dir}->subdir('fs_based');
    ok(-d $dir, 'fs_based data dir exists');

    my $run = $test{class}->new($dir);
    ok($run, 'create run');

	my $expected_stages = {
		'0-rawreads' => {
			'substages' => {
				'daligner-runs' => '865.437',
			},
			'duration' => '865.437',
		},
		'1-preads_ovl' => {
			'duration' => '399.28',
			'substages' => {
				'daligner-chunks' => '1.905',
				'daligner-runs' => '396.219',
				'daligner-combine' => '0.343',
				'daligner-split' => '0.362',
				'daligner-gathered' => '0.451',
			},
		},
		'2-asm-falcon' => {
			'duration' => '115.335',
		},
		'3-unzip' => {
			'duration' => '2961.471',
			'substages' => {
				'0-phasing phasing-chunks' => '8.187',
				'2-htigs' => '2952.761',
				'2-htigs chunks' => '0.523',
			},
		},
		'4-polish' => {
			'substages' => {
				'quiver-run' => '279.946',
				'segregate-chunks' => '0.519',
				'quiver-chunks' => '0.729',
			},
			'duration' => '281.194',
		},
	};

	my $stages = $run->get_stages;
	is_deeply($stages, $expected_stages, 'got stages');

};

done_testing();
