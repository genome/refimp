#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Path::Class;
use Sub::Install;
use Test::More tests => 3;

my $pkg = 'RefImp::Tenx::Command::LongrangerBase';
use_ok($pkg);
class LongrangerTest {
    is => 'RefImp::Tenx::Command::LongrangerBase',
};
sub LongrangerTest::output_directory { dir('.')->absolute }
sub LongrangerTest::_validate_pre_tenx_command { 1 }
sub LongrangerTest::_tenx_command { ('longranger') }
sub LongrangerTest::_validate_post_tenx_command { 1 }
sub LongrangerTest::_create_db_entities { 1 }
my $cmd = LongrangerTest->create;

subtest 'execute' => sub{
    plan tests => 1;

    # Don't run bsub/longranger command
    my $bsub_command = LongrangerTest->can('_bsub_command');
    Sub::Install::reinstall_sub({
            code => sub{ (qw/ echo Hi ho Silver /) },
            as => '_bsub_command',
            into => 'LongrangerTest',
        });

    ok($cmd->execute, 'execute');

    # Reinstate
    Sub::Install::reinstall_sub({
            code => $bsub_command,
            as => '_bsub_command',
            into => 'LongrangerTest',
        });

};

subtest 'bsub properties and cmd' => sub{
    plan tests => 2;

    my $bsub_out_file = $cmd->bsub_out_file->stringify;
    like($bsub_out_file, qr/longranger\-out\-/, 'bsub_out_file');

    my @bsub_cmd = $cmd->_bsub_command;
    my $mem = $cmd->bsub_mem;
    my $queue = $cmd->bsub_queue;
    my @expected_bsub_cmd = (
        'bsub', '-K',
        '-R', "select[mem>$mem] rusage[mem=$mem]",
        '-M', ( $mem * 1200  ),
        '-oo', $bsub_out_file,
        '-q', $queue,
        '-a', 'docker(registry.gsc.wustl.edu/ebelter/longranger:2.1.3)',
    );
    is_deeply(\@bsub_cmd, \@expected_bsub_cmd, '_bsub_command');

};

done_testing();
