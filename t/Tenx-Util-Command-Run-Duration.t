#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::Exception;
use Test::More tests => 2;
use Path::Class;

use TestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    %test = ( class => 'Tenx::Util::Command::Run::Duration' );
    use_ok($test{class}) or die;

    $test{data_dir} = TestEnv::test_data_directory_for_class('Tenx::Util::Run');
    ok(-d $test{data_dir}, 'data dir exists');

};

subtest 'execute' => sub{
    plan tests => 3;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    my $cmd = $test{class}->create(directory => $test{data_dir}->subdir('supernova-success')->stringify);
    lives_ok(sub{ $cmd->execute; }, 'execute');
    ok($cmd->result, 'execute ok');
    like($output, qr/^STATUS\:\s+success/, 'report matches');

};

done_testing();
