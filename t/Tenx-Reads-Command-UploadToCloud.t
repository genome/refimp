#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Path::Class;
use Test::Exception;
use Test::Mock::Cmd 'system' => \&system_mock;
use Test::More tests => 3;

my %test = (
    class => 'Tenx::Reads::Command::UploadToCloud',
    samples => [qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /],
);
my $rsync_cnt = 0;
sub system_mock {
    is_deeply(
        \@_,
        [
            qw/ gsutil rsync -r /,
            $test{sample_sheet}->fastq_directory_for_sample_name($test{samples}->[$rsync_cnt]),
            'gs://reads/'.$test{samples}->[$rsync_cnt]
        ],
        'correct subcommand for '.$test{samples}->[$rsync_cnt]
    );
    $rsync_cnt++;
    0;
}

subtest 'setup' => sub{
    plan tests => 3;

    use_ok($test{class}) or die;

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Reads')->subdir('sample-sheet');
    ok(-d "$test{data_dir}", 'data dir exists');

    $test{sample_sheet} = Tenx::Reads::MkfastqRun->create($test{data_dir});
    ok($test{sample_sheet});

};

subtest 'upload to cloud' => sub{
    plan tests => 10;

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
    plan tests => 2;

    my $cmd = $test{class}->create(
        directory => "$test{data_dir}",
        destination => 'gs:/reads',
        samples => [qw/ M_FA-1CNTRL-Control_10x M_FA-2PD1-aPD1_10x M_FA-4PDCTLA-aPD1-aCTLA4_10x /],
    );
    ok($cmd, 'create cmd');

    throws_ok(sub{ $cmd->execute }, qr/Unknown destination/, 'fails w/ invalid destination')

};

done_testing();
