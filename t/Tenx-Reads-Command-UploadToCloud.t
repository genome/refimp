#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use IPC::Cmd;
use Path::Class;
use Sub::Install;
use Test::Exception;
use Test::More tests => 3;

my %test = (
    class => 'Tenx::Reads::Command::UploadToCloud',
    samples => [qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /],
    success => 1,
);
subtest 'setup' => sub{
    plan tests => 3;

    use_ok($test{class}) or die;

    $test{data_dir} = TestEnv::test_data_directory_for_class('RefImp::Reads')->subdir('sample-sheet');
    ok(-d "$test{data_dir}", 'data dir exists');

    $test{sample_sheet} = Tenx::Reads::MkfastqRun->create($test{data_dir});
    ok($test{sample_sheet});

	my $rsync_cnt = 0;
    $test{mock_gcp_rsync} = sub{
        my %p = @_;
		is_deeply(
			\%p,
            {
                command => [qw/ gsutil rsync -r /, $test{sample_sheet}->fastq_directory_for_sample_name($test{samples}->[$rsync_cnt]), 'gs://reads/'.$test{samples}->[$rsync_cnt] ],
                verbose => 0,
            },
			'correct subcommand for '.$test{samples}->[$rsync_cnt]
		);
		$rsync_cnt++;
		( 1, '' );
	};
    $test{mock_gcp_rsync_fail} = sub{ ( 0, 'gsutil not found' ); };

};

subtest 'upload to cloud' => sub{
    plan tests => 10;

	Sub::Install::reinstall_sub({
			code => sub{ $test{mock_gcp_rsync}->(@_); },
			as => 'run',
            into => 'IPC::Cmd',
        });

    my $cmd = $test{class}->create(
        directory => "$test{data_dir}",
        destination => 'gs://reads',
        samples => [qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /],
    );
    ok($cmd, 'create cmd');

    my $error;
    open local(*STDERR), '>', \$error or die $!;

    lives_ok(sub{ $cmd->execute; }, 'execute');
    ok($cmd->result, 'execute succeeded');

    like($error, qr/Uploading M_FA-1CNTRL-Control_10x/, 'uploaded correct sample');
    like($error, qr/Uploading M_FA-2PD1-aPD1_10x/, 'uploaded correct sample');
    like($error, qr/Uploading M_FA-4PDCTLA-aPD1-aCTLA4_10x/, 'uploaded correct sample');
    like($error, qr/Skipping M_FA-3CTLA4-aCTLA4_10x/, 'skipped correct sample');

};

subtest 'fails' => sub{
    plan tests => 4;

    my $error;
    open local(*STDERR), '>', \$error or die $!;

    my $cmd = $test{class}->create(
        directory => "$test{data_dir}",
        destination => 'gs:/reads',
        samples => [qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /],
    );
    ok($cmd, 'create cmd');
    throws_ok(sub{ $cmd->execute }, qr/Unknown destination/, 'fails w/ invalid destination');

	Sub::Install::reinstall_sub({
			code => sub{ $test{mock_gcp_rsync_fail}->(@_); },
			as => 'run',
            into => 'IPC::Cmd',
        });
    $cmd = $test{class}->create(
        directory => "$test{data_dir}",
        destination => 'gs://reads',
        samples => [qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /],
    );
    ok($cmd, 'create cmd');
    throws_ok(sub{ $cmd->execute }, qr/Failed to run gsutil/, 'fails when gsutil fails');

};

done_testing();
