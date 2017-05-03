#!/usr/bin/env perl5.10.1

use strict;
use warnings 'FATAL';

use TestEnv;
use Test::More tests => 3;

my $pkg = 'RefImp::Assembly::Submission::TblToAsn';
my $cmd;
subtest 'setup' => sub {
    plan tests => 3;

    use_ok($pkg) or die;

    my $submission_yml = File::Spec->join(TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission'), 'submission.yml');
    my $submission = RefImp::Assembly::Submission->create_from_yml($submission_yml);
    ok($submission, 'created submission from yml');

    $cmd = $pkg->create(submission => $submission);
    ok($cmd, 'create command');

};

subtest 'submission_authors' => sub{
    plan tests => 1;

    my $expected_authors = join(
        "\n",
        '{ name name { last "Warren" , first "Wesley" , initials "W.C." } } ,',
        '{ name name { last "Gomez-Chiarri" , first "Marta" , initials "M." } } ,',
        '{ name name { last "Tomlinson" , first "Chad" , initials "C." } } ,',
    );
    is($cmd->formatted_submission_authors, $expected_authors, 'formatted_submission_authors');

};

subtest 'execute' => sub{
    plan tests => 2;

    ok($cmd->execute);
    ok($cmd->result, 'execute');

};

done_testing();
