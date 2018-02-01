#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Date::Format;
use Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 3;

my %setup;
subtest 'setup' => sub{
    plan tests => 2;

    $setup{pkg} = 'RefImp::Assembly::Command::Submit';
    use_ok($setup{pkg}) or die;

    my $data_dir = TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission');
    my $assembly_dir = File::Spec->join($data_dir, 'assembly');
    $setup{submission_yml} = File::Spec->join($data_dir, 'submission.yml');

    Sub::Install::reinstall_sub({
        code => sub{ 1 },
        as => 'validate_for_submit',
        into => 'RefImp::Assembly::Submission',    
        });

    $setup{ftp} = TestEnv::NcbiFtp->setup;
    ok(TestEnv::NcbiBiosample->setup, 'biosample setup');

};

subtest 'execute fails' => sub{
    plan tests => 1;

    throws_ok(sub{ $setup{pkg}->execute(submission_yml => '/blah'); }, qr/Submission YAML does not exist/, 'execute fails w/ non existing submission yml');

};

subtest 'execute' => sub{
    plan tests => 7;

    my $cmd = $setup{pkg}->create(submission_yml => $setup{submission_yml});

    $setup{ftp}->mock('cwd', sub{ is($_[1], 'TEMP', 'correct cwd'); });
    $setup{ftp}->mock('put', sub{ is($_[1], $cmd->tar_file); });
    $setup{ftp}->mock('size', sub{ -s $cmd->tar_file; });

    ok($cmd->execute, 'execute submit');
    ok($cmd->result, 'cmd result');

    ok($cmd->submission, 'created submission');
    like($cmd->tar_file, qr/Crassostrea_virginica_2\.0_\d\d\d\d\-\d\d\-\d\d\.tar/, 'tar_file');

    ok(-s $cmd->tar_file, 'created tar file');

};

done_testing();
