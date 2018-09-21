#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 3;

my %setup;
subtest 'setup'=> sub{
    plan tests => 3;

    $setup{pkg} = 'RefImp::Assembly::Command::Submission::Email';
    use_ok($setup{pkg}) or die;

    ok(TestEnv::NcbiBiosample->setup, 'biosample setup');

    $setup{submission_yml} = File::Spec->join(TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission'), 'submission.yml');
    ok(-s $setup{submission_yml}, 'submission yml exists');

};

subtest 'execute fails' => sub{
    plan tests => 1;

    throws_ok(sub{ $setup{pkg}->execute(); }, qr/'submission': No value/, 'execute fails w/o submission');

};

subtest 'execute with submission' => sub{
    plan tests => 3;

    my $submission = RefImp::Assembly::Submission->get_or_define_from_yml($setup{submission_yml});
    ok($submission, 'create submission');

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $setup{pkg}->execute(submission => $submission); }, 'execute with submission');
    like($output, qr/To: genomes/, 'correct output');

};

done_testing();
