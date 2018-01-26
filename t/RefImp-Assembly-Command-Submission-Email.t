#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 4;

my %setup;
subtest 'setup'=> sub{
    plan tests => 3;

    $setup{pkg} = 'RefImp::Assembly::Command::Submission::Email';
    use_ok($setup{pkg}) or die;

    ok(TestEnv::NcbiBiosample->setup, 'biosample setup');

    $setup{submission_yml} = File::Spec->join(TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission'), 'submission.yml');
    ok(-s $setup{submission_yml}, 'submission yml exists');

};

subtest 'execute with submission yml' => sub{
    plan tests => 1;

    throws_ok(sub{ $setup{pkg}->execute(); }, qr/No submission or submission_yml given/, 'execute fails w/o submission or submission yml');

};

subtest 'execute with submission yml' => sub{
    plan tests => 2;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $setup{pkg}->execute(submission_yml => $setup{submission_yml}); }, 'execute with submission_yml');
    like($output, qr/To: genomes/, 'correct output');

};

subtest 'execute with submission' => sub{
    plan tests => 3;

    my $submission = RefImp::Assembly::Submission->define_from_yml($setup{submission_yml});
    ok($submission, 'create submission');

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $setup{pkg}->execute(submission => $submission); }, 'execute with submission');
    like($output, qr/To: genomes/, 'correct output');

};

done_testing();
