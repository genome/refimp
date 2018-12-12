#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Temp 'tempdir';
use File::Touch 'touch';
use IPC::Cmd;
use Path::Class qw/ dir file/;
use Sub::Install;
use Test::Exception;
use Test::More tests => 3;

my %test = (
    class => 'Tenx::Assembly::Command::DownloadFromCloud',
    success => 1,
);
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{class}) or die;
    use_ok('RefImp::Assembly');

    $test{tempdir} = dir( tempdir(CLEANUP => 1) );

	my $cnt = 0;

    my $destination = $test{tempdir}->subdir('SAMPLE1');
    my @commands = (
        [ 'gsutil', 'cp', 'gs://data/assembly/SAMPLE1/_log', $destination, ],
        [ 'gsutil', 'cp', 'gs://data/assembly/SAMPLE1/outs/report.txt', $destination->subdir('outs'), ],
        [ 'gsutil', 'cp', 'gs://data/assembly/SAMPLE1/outs/summary.csv', $destination->subdir('outs'), ],
    );
    for ( RefImp::Assembly->mkoutput_types ) {
        push @commands, [ 'gsutil', 'cp', sprintf('gs://data/assembly/SAMPLE1/mkoutput/SAMPLE1.%s.*fasta.gz', $_), $destination->subdir('mkoutput'), ];
    }

    $test{mock_gcp_cp} = sub{
        my %p = @_;
		is_deeply(
			\%p,
            {
                command => $commands[$cnt],
                verbose => 0,
            },
			"correct subcommand number $cnt",
		);
		$cnt++;
        touch( dir($p{command}->[3])->file( file($p{command}->[2])->basename )->stringify );
		( 1, '' );
	};
    $test{mock_gcp_cp_fail} = sub{ ( 0, 'gsutil not found' ); };

};

subtest 'download from cloud' => sub{
    plan tests => 14;

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

    my $dir = $test{tempdir}->subdir('SAMPLE1');
    ok(-d $dir, 'created SAMPLE1 subdir');

    my $outs_dir = $dir->subdir('outs');
    ok(-d $outs_dir, 'created outs subdir');
    ok(-e $outs_dir->file('report.txt'), 'retrieved report.txt');
    ok(-e $outs_dir->file('summary.csv'), 'retrieved summary.csv');

    my $mkoutput_dir = $dir->subdir('mkoutput');
    ok(-d $mkoutput_dir, 'created mkoutput subdir');

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
