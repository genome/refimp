#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::More tests => 3;

use TenxTestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 4;

    %test = ( class => 'Tenx::Util::Run::Report::Summary' );
    use_ok($test{class}) or die;
    use_ok('Tenx::Util::Run') or die;

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Util::Run');
    ok(-d $test{data_dir}, 'data dir exists');

    my @runs = map { Tenx::Util::Run->new($test{data_dir}->subdir($_)) } (qw/ supernova-success /);
    push @runs, Tenx::Util::Run->new($test{data_dir}->subdir('supernova-success'));
    ok(@runs, 'created runs');
    $test{runs} = \@runs;

};

subtest 'generate_csv' => sub{
    plan tests => 2;

    my $csv = $test{class}->generate_csv(@{$test{runs}});
    ok($csv, 'generate_csv');
    like($csv, qr/^assembly_size,barcode_fraction,bases_per_read/, 'csv matches');

};

subtest 'generate_yaml' => sub{
    plan tests => 2;

    my $yaml = $test{class}->generate_yaml(@{$test{runs}});
    ok($yaml, 'generate_yaml');
    like($yaml, qr/^---\nassembly_size:/, 'yaml matches');

};

done_testing();
