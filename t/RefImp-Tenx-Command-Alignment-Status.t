#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 5;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    $test{pkg} = 'RefImp::Tenx::Command::Alignment::Status';
    use_ok($test{pkg}) or die;

    $test{alignment} = RefImp::Tenx::Alignment->__define__(
        directory => '/tmp',
        reads => RefImp::Tenx::Reads->__define__(directory => '/tmp', sample_name => 'TESTY'),
        reference => RefImp::Tenx::Reference->__define__(directory => '/tmp', name => 'TESTY'),
    );
    ok($test{alignment}, 'define alignment') or die;

    $test{data_dir} = dir( TestEnv::test_data_directory_for_package('RefImp::Tenx::Alignment') );

};

subtest 'succeded determined by log' => sub{ 
    plan tests => 4;

    my $succeeded_dir = $test{data_dir}->subdir('succeeded');
    ok(-d $succeeded_dir, 'succeeded dir exists');
    $test{alignment}->directory( $succeeded_dir->stringify );
    
    my $output;
    open local(*STDERR), '>', \$output or die $!;
    lives_ok(sub{ $test{pkg}->execute(alignment => $test{alignment}); }, 'alignment status is succeeded');
    like($output, qr/Status:\s+SUCCEEDED/, 'output has correct');
    unlike($output, qr/Refining status from journal/, 'output does not include refining from journal');

};

subtest 'failed determined by log' => sub{
    plan tests => 4;

    my $failed_dir = $test{data_dir}->subdir('failed');
    ok(-d $failed_dir->stringify, 'failed dir exists');
    $test{alignment}->directory( $failed_dir->stringify );

    my $output;
    open local(*STDERR), '>', \$output or die $!;
    lives_ok(sub{ $test{pkg}->execute(alignment => $test{alignment}); }, 'alignment status is failed');
    like($output, qr/Status:\s+FAILED/, 'output has correct status');
    unlike($output, qr/Refining status from journal/, 'output does not include refining from journal');

};

subtest 'running determined by journal' => sub{
    plan tests => 4;

    my $running_dir = $test{data_dir}->subdir('running');
    ok(-d $running_dir->stringify, 'running dir exists');
    $test{alignment}->directory( $running_dir->stringify);

    my $journal = $running_dir->subdir('journal');
    system('touch', $journal->stringify);

    my $output;
    open local(*STDERR), '>', \$output or die $!;
    lives_ok(sub{ $test{pkg}->execute(alignment => $test{alignment}); }, 'alignment status is running');
    like($output, qr/Status:\s+RUNNING/, 'output has correct status');
    like($output, qr/Refining status from journal/, 'output does include refining from journal');

};

subtest 'died determined by journal' => sub{
    plan tests => 4;

    my $running_dir = $test{data_dir}->subdir('running');
    ok(-d $running_dir->stringify, 'running dir exists');
    $test{alignment}->directory( $running_dir->stringify );
    my $journal = $running_dir->subdir('journal');
    system('touch', '-m', '-d', '1 Jan 2001 00:00', $journal->stringify);

    my $output;
    open local(*STDERR), '>', \$output or die $!;
    lives_ok(sub{ $test{pkg}->execute(alignment => $test{alignment}); }, 'alignment status is died');
    like($output, qr/Status:\s+DIED/, 'output has correct status');
    like($output, qr/Refining status from journal/, 'output does include refining from journal');

};

done_testing();
