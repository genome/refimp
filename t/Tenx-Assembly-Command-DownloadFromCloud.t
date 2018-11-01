#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use File::Temp 'tempdir';
use IPC::Cmd;
use Path::Class 'dir';
use Sub::Install;
use Test::Exception;
use Test::More tests => 3;

my %test = (
    class => 'Tenx::Assembly::Command::DownloadFromCloud',
    success => 1,
);
subtest 'setup' => sub{
    plan tests => 3;

    use_ok($test{class}) or die;
    use_ok('Tenx::Assembly');

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Assembly')->subdir('success');
    ok(-d "$test{data_dir}", 'data dir exists');
    $test{tempdir} = dir( tempdir(CLEANUP => 1) );

	my $cnt = 0;
    my @types = Tenx::Assembly->mkoutput_types;
    $test{mock_gcp_cp} = sub{
        my %p = @_;
		is_deeply(
			\%p,
            {
                command => [ 'gsutil', 'cp', sprintf('gs://data/assembly/SAMPLE1/mkoutput/SAMPLE1.%s.*fasta.gz', $types[$cnt]), $test{tempdir}->subdir('SAMPLE1'), ],
                verbose => 0,
            },
			'correct subcommand for '.$types[$cnt]
		);
		$cnt++;
		( 1, '' );
	};
    $test{mock_gcp_cp_fail} = sub{ ( 0, 'gsutil not found' ); };

};

subtest 'download from cloud' => sub{
    plan tests => 7;

	Sub::Install::reinstall_sub({
			code => sub{ $test{mock_gcp_cp}->(@_); },
			as => 'run',
            into => 'IPC::Cmd',
        });

    my $cmd = $test{class}->create(
        assembly => 'gs://data/assembly/SAMPLE1',
        destination => "$test{tempdir}",
    );
    ok($cmd, 'create cmd');

    my $error;
    open local(*STDERR), '>', \$error or die $!;

    lives_ok(sub{ $cmd->execute; }, 'execute');
    ok($cmd->result, 'execute succeeded');
    ok(-d $test{tempdir}->subdir('SAMPLE1'), 'created SAMPLE1 subdir');

};

subtest 'fails' => sub{
    plan tests => 3;

    my $error;
    open local(*STDERR), '>', \$error or die $!;

	Sub::Install::reinstall_sub({
			code => sub{ $test{mock_gcp_cp_fail}->(@_); },
			as => 'run',
            into => 'IPC::Cmd',
        });
    my $cmd = $test{class}->create(
        assembly => 'gs://data/assembly/SAMPLE2',
        destination => "$test{tempdir}",
    );
    ok($cmd, 'create cmd');
    throws_ok(sub{ $cmd->execute }, qr/Failed to run gsutil/, 'fails when gsutil fails');
    ok(-d $test{tempdir}->subdir('SAMPLE1'), 'created SAMPLE2 subdir');

};

done_testing();
