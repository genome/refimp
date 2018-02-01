#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Path::Class;
use Test::Exception;
use Test::More tests => 3;

my %test;
subtest 'setup' => sub{
    plan tests => 4;

    $test{pkg} = 'RefImp::Assembly::Command::Submission::Create';
    use_ok($test{pkg}) or die;

    $test{taxon} = RefImp::Taxon->create(name => 'Eastern Oyster', species_name => 'Crassostrea virginica');
    ok($test{taxon}, 'create taxon');

    my $data_dir = dir( TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission') );
    $test{submission_yml} = $data_dir->file('submission.yml');
    ok(-s $test{submission_yml}, 'submission_yml exists');

    ok(TestEnv::NcbiBiosample->setup, 'biosample setup');

};

subtest 'fails' => sub{
    plan tests => 1;

    throws_ok(sub{ $test{pkg}->execute(submission_yml => $test{submission_yml}->stringify, submitted_on => 'blah'); }, qr/Invalid submitted_on/, 'fails w/ invlaid submitted_on');

};

subtest 'create' => sub{
    plan tests => 6;

    my $cmd;
    lives_ok(
        sub{ $cmd = $test{pkg}->execute(
                submission_yml => $test{submission_yml}->stringify,
                submitted_on => '2001-01-01',
            ); },
        'execute assembly submission create',
    );
    ok($cmd->result, 'execute successful');

    my $submission = $cmd->submission;
    ok($submission, 'created submission');
    is($submission->submitted_on, '2001-01-01', 'set submission submitted_on');

    my $assembly = $submission->assembly;
    ok($assembly, 'assembly created');

    ok(UR::Context->commit, 'commit');

};

done_testing();
