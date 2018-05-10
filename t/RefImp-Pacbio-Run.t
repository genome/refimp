#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::More tests => 2;
use Test::Exception;

my %test = ( class => 'RefImp::Pacbio::Run', );
subtest 'new' => sub{
    plan tests => 6;

    use_ok($test{class}) or die;

    my $directory = dir( TestEnv::test_data_directory_for_package($test{class}) );
    ok(-d "$directory", "example run directory exists");

    my $run = $test{class}->new($directory);
    ok($run, 'create run');
    ok($run->directory, 'directory');

    $test{run} = $run;

    throws_ok(sub{ $test{class}->new; }, qr/No directory given/, 'fails w/o directory');
    throws_ok(sub{ $test{class}->new('blah'); }, qr/Directory given does not exist/, 'fails w/ invalid directory');

};

subtest 'analyses' => sub{
    plan tests => 4;

    my $run = $test{run};
	my $analyses = $run->analyses;
    ok($analyses, 'run analyses');
    is(@$analyses, 10, 'correct number of analyses');
    #my $expected_files = _expected_analysis_files();
    #is_deeply($files, $expected_files, 'samples_and_analysis_files');

	my $sample_analyses = $run->analyses_for_sample(qr/^NA19434_4808o3_lib1_50pM/);
    is_deeply($sample_analyses, $analyses, 'analyses_for_sample');

    throws_ok(sub{ $test{run}->analyses_for_sample; }, qr/No sample name regex given/, 'analyses_for_sample fails w/o sample name regex');

};

done_testing();

###

sub _expected_analysis_files {
	{
		'NA19434_4808o3_lib1_50pM_A1' => [
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/A01_1/Analysis_Results/m160819_231415_00116_c101036512550000001823251411171640_s1_p0.1.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/A01_1/Analysis_Results/m160819_231415_00116_c101036512550000001823251411171640_s1_p0.2.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/A01_1/Analysis_Results/m160819_231415_00116_c101036512550000001823251411171640_s1_p0.3.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/A01_1/Analysis_Results/m160819_231415_00116_c101036512550000001823251411171640_s1_p0.bas.h5'
		],
		'NA19434_4808o3_lib1_50pM_A2' => [
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/A02_1/Analysis_Results/m160822_003114_00116_c101036752550000001823251411171640_s1_p0.1.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/A02_1/Analysis_Results/m160822_003114_00116_c101036752550000001823251411171640_s1_p0.2.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/A02_1/Analysis_Results/m160822_003114_00116_c101036752550000001823251411171640_s1_p0.3.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/A02_1/Analysis_Results/m160822_003114_00116_c101036752550000001823251411171640_s1_p0.bas.h5'
		],
		'NA19434_4808o3_lib1_50pM_B1' => [
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/B01_1/Analysis_Results/m160820_053721_00116_c101036512550000001823251411171641_s1_p0.1.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/B01_1/Analysis_Results/m160820_053721_00116_c101036512550000001823251411171641_s1_p0.2.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/B01_1/Analysis_Results/m160820_053721_00116_c101036512550000001823251411171641_s1_p0.3.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/B01_1/Analysis_Results/m160820_053721_00116_c101036512550000001823251411171641_s1_p0.bas.h5'
		],
		'NA19434_4808o3_lib1_50pM_B2' => [
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/B02_1/Analysis_Results/m160822_045426_00116_c101036752550000001823251411171641_s1_p0.1.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/B02_1/Analysis_Results/m160822_045426_00116_c101036752550000001823251411171641_s1_p0.2.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/B02_1/Analysis_Results/m160822_045426_00116_c101036752550000001823251411171641_s1_p0.3.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/B02_1/Analysis_Results/m160822_045426_00116_c101036752550000001823251411171641_s1_p0.bas.h5'
		],
		'NA19434_4808o3_lib1_50pM_C1' => [
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/C01_1/Analysis_Results/m160820_120016_00116_c101036512550000001823251411171642_s1_p0.1.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/C01_1/Analysis_Results/m160820_120016_00116_c101036512550000001823251411171642_s1_p0.2.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/C01_1/Analysis_Results/m160820_120016_00116_c101036512550000001823251411171642_s1_p0.3.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/C01_1/Analysis_Results/m160820_120016_00116_c101036512550000001823251411171642_s1_p0.bas.h5'
		],
		'NA19434_4808o3_lib1_50pM_D1' => [
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/D01_1/Analysis_Results/m160820_182317_00116_c101036512550000001823251411171643_s1_p0.1.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/D01_1/Analysis_Results/m160820_182317_00116_c101036512550000001823251411171643_s1_p0.2.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/D01_1/Analysis_Results/m160820_182317_00116_c101036512550000001823251411171643_s1_p0.3.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/D01_1/Analysis_Results/m160820_182317_00116_c101036512550000001823251411171643_s1_p0.bas.h5'
		],
		'NA19434_4808o3_lib1_50pM_E1' => [
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/E01_1/Analysis_Results/m160821_004554_00116_c101036512550000001823251411171644_s1_p0.1.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/E01_1/Analysis_Results/m160821_004554_00116_c101036512550000001823251411171644_s1_p0.2.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/E01_1/Analysis_Results/m160821_004554_00116_c101036512550000001823251411171644_s1_p0.3.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/E01_1/Analysis_Results/m160821_004554_00116_c101036512550000001823251411171644_s1_p0.bas.h5'
		],
		'NA19434_4808o3_lib1_50pM_F1' => [
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/F01_1/Analysis_Results/m160821_070940_00116_c101036512550000001823251411171645_s1_p0.1.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/F01_1/Analysis_Results/m160821_070940_00116_c101036512550000001823251411171645_s1_p0.2.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/F01_1/Analysis_Results/m160821_070940_00116_c101036512550000001823251411171645_s1_p0.3.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/F01_1/Analysis_Results/m160821_070940_00116_c101036512550000001823251411171645_s1_p0.bas.h5'
		],
		'NA19434_4808o3_lib1_50pM_G1' => [
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/G01_1/Analysis_Results/m160821_133539_00116_c101036512550000001823251411171646_s1_p0.1.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/G01_1/Analysis_Results/m160821_133539_00116_c101036512550000001823251411171646_s1_p0.2.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/G01_1/Analysis_Results/m160821_133539_00116_c101036512550000001823251411171646_s1_p0.3.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/G01_1/Analysis_Results/m160821_133539_00116_c101036512550000001823251411171646_s1_p0.bas.h5'
		],
		'NA19434_4808o3_lib1_50pM_H1' => [
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/H01_1/Analysis_Results/m160821_175820_00116_c101036512550000001823251411171647_s1_p0.1.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/H01_1/Analysis_Results/m160821_175820_00116_c101036512550000001823251411171647_s1_p0.2.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/H01_1/Analysis_Results/m160821_175820_00116_c101036512550000001823251411171647_s1_p0.3.bax.h5',
			'/home/ebelter/dev/refimp/t/data/RefImp-Pacbio-Run/6U00FA/H01_1/Analysis_Results/m160821_175820_00116_c101036512550000001823251411171647_s1_p0.bas.h5'
		],
	};
}
