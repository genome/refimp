#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 2;

my %setup;
subtest 'setup'=> sub{
    plan tests => 3;

    $setup{pkg} = 'RefImp::Assembly::Command::Submission::View';
    use_ok($setup{pkg}) or die;

    ok(TestEnv::NcbiBiosample->setup, 'biosample setup');

    my $submission_yml = File::Spec->join(TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission'), 'submission.yml');
    $setup{submission} = RefImp::Assembly::Submission->create_from_yml($submission_yml);
    ok($setup{submission}, 'create submission');

};

subtest 'execute' => sub{
    plan tests => 2;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $setup{pkg}->execute(submission => $setup{submission}); }, 'execute view cmd');
    like($output, qr/Crassostrea_virginica_2\.0/, 'correct output');

};

done_testing();
