#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Sub::Install;
use Test::Exception;
use Test::More tests => 3;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    $test{pkg} = 'RefImp::Assembly::Command::Submission::VerifyTgzUploaded';
    use_ok($test{pkg}) or die;

    my $data_dir = dir( TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission') );
    my $assembly_dir = File::Spec->join($data_dir, 'assembly');

    $test{submission} = RefImp::Assembly::Submission->get_or_define_from_yml( File::Spec->join($data_dir, 'submission.yml') );
    ok($test{submission}, 'create submission');

    $test{ftp} = TestEnv::NcbiFtp->setup;
    $test{ftp}->mock('cwd', sub{ 1 });

};

subtest 'execute no tar exists' => sub{
    plan tests => 3;

    $test{ftp}->mock('size', sub{ 0 });

    my $cmd = $test{pkg}->create(submission => $test{submission});
    ok($cmd, 'create command');
    ok($cmd->execute, 'execute');
    is($cmd->status_message, 'Submission TGZ file NOT found.', 'correct status message');

};

subtest 'execute' => sub{
    plan tests => 3;

    $test{ftp}->mock('size', sub{ 1 });
    
    my $cmd = $test{pkg}->create(submission => $test{submission});
    ok($cmd, 'create command');
    ok($cmd->execute, 'execute');
    is($cmd->status_message, 'Found submission TGZ file.', 'correct status message');

};

done_testing();
