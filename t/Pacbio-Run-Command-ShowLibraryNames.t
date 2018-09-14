#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use File::Slurp;
use Path::Class;
use Test::More tests => 1;
use Test::Exception;

my %test = ( class => 'Pacbio::Run::Command::ShowLibraryNames', );
subtest 'execute' => sub{
    plan tests => 6;

    use_ok($test{class}) or die;

    $test{data_dir} = TenxTestEnv::test_data_directory_for_class( $test{class} );
    ok(-d "$test{data_dir}", "data dir exists");
    my $directory = TenxTestEnv::test_data_directory_for_class('Pacbio::Run')->subdir('6U00E3');
    ok(-d "$directory", "example run directory exists");

    my $output;
    open local(*STDOUT), '>', \$output or die $!;

    my $cmd = $test{class}->create(
        machine_type => 'rsii',
        run_directory => "$directory",
        library_name => 'HG',
    );
    ok($cmd, 'create command');
    lives_ok(sub{ $cmd->execute; }, 'execute');

    my $expected_output = File::Slurp::slurp( $test{data_dir}->file('expected.out') );
    my $base_test_data_dir = TenxTestEnv::test_data_directory();
    $expected_output =~ s/\%TDD/$base_test_data_dir/g;
    is($output, $expected_output, 'output matches');
    #File::Slurp::write_file($test{data_dir}->file('got'), $output);

};

done_testing();
