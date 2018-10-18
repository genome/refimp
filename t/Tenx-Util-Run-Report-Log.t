#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::More tests => 2;
use Path::Class;

use TenxTestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 4;

    %test = ( class => 'Tenx::Util::Run::Report::Log' );
    use_ok($test{class}) or die;
    use_ok('Tenx::Util::Run') or die;

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Util::Run');
    ok(-d $test{data_dir}, 'data dir exists');

    #my @runs = map { Tenx::Util::Run->new($test{data_dir}->subdir($_)) } (qw/ supernova-success /);
    my @runs = ( Tenx::Util::Run->new(dir("/home/ebelter/dev/tenx")) );
    push @runs, Tenx::Util::Run->new($test{data_dir}->subdir('supernova-success'));
    ok(@runs, 'created runs');
    $test{runs} = \@runs;

};

subtest 'generate_stage_status' => sub{
    plan tests => 2;

    my $report = $test{class}->generate_stage_status(@{$test{runs}});
    ok($report, 'generate_stage_status');
    like($report, qr/^STATUS\:\s+success/, 'report matches');

};

done_testing();
