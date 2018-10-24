#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::Exception;
use Test::More tests => 4;

use TenxTestEnv;

my %test;
diag("FIXME This mostly works");
subtest 'setup' => sub{
    plan tests => 3;

    %test = ( class => 'Tenx::Util::Command::Run::Summary' );
    use_ok($test{class}) or die;
    use_ok('Tenx::Util::Run') or die;

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Tenx::Util::Run');
    ok(-d $test{data_dir}, 'data dir exists');
    my $run_directory = $test{data_dir}->subdir('supernova-success')->stringify;
    $test{directories} = [ $run_directory, $run_directory ];

};

subtest 'generate_csv' => sub{
    plan tests => 3;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    my $cmd = $test{class}->create(directories => $test{directories}, as => 'csv');
    lives_ok(sub{ $cmd->execute; }, 'execute');
    ok($cmd->result, 'generate_csv');
    like($output, qr/^assembly_size,barcode_fraction,bases_per_read/, 'csv matches');

};

subtest 'generate_table' => sub{
    plan tests => 3;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    my $cmd = $test{class}->create(directories => $test{directories}->[0], as => 'table');
    lives_ok(sub{ $cmd->execute; }, 'execute');
    ok($cmd->result, 'generate_table');
    like($output, qr/^ASSEMBLY_SIZE\s+BARCODE_FRACTION\s+BASES_PER_READ/, 'table matches');

};

subtest 'generate_yaml' => sub{
    plan tests => 3;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    my $cmd = $test{class}->create(directories => $test{directories}, as => 'yaml');
    lives_ok(sub{ $cmd->execute; }, 'execute');
    ok($cmd->result, 'generate_yaml');
    like($output, qr/^---\nassembly_size:/, 'yaml matches');

};

done_testing();
