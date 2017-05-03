#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Slurp;
use File::Temp 'tempdir';
use LWP::UserAgent;
require RefImp::Assembly::Submission;
use Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 3;
use YAML;

my %setup;
subtest 'setup' => sub{
    plan tests => 1;

    $setup{pkg} = 'RefImp::Assembly::Command::Submit';
    use_ok($setup{pkg}) or die;

    my $data_dir = TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission');
    my $assembly_dir = File::Spec->join($data_dir, 'assembly');
    $setup{submission_yml} = File::Spec->join($data_dir, 'submission.yml');
    $setup{tempdir} = tempdir(CLEANUP => 1);

    Sub::Install::reinstall_sub({
        code => sub{ 1 },
        as => 'validate_for_submit',
        into => 'RefImp::Assembly::Submission',    
        });

};

subtest 'execute fails' => sub{
    plan tests => 1;

    throws_ok(sub{ $setup{pkg}->execute(submission_yml => '/blah'); }, qr/Submission YAML does not exist/, 'execute fails w/ non existing submission yml');

};

subtest 'execute' => sub{
    plan tests => 2;

    my $cmd = $setup{pkg}->execute(submission_yml => $setup{submission_yml});
    ok($cmd->result, 'execute submission');
    ok($cmd->submission, 'created submission');

};

done_testing();
