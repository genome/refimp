#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my %setup;
subtest "setup" => sub{
    plan tests => 3;

    my $pkg = "RefImp::Resources::Ncbi::SubmissionReport";
    use_ok($pkg) or die;
    $setup{file} = File::Spec->join(
        TestEnv::test_data_directory_for_package($pkg),
        "wugsc20160707.HMPB-AAD13A05.phase3.fa2htgs.asn.ac4htgs",
    );

    $setup{project} = RefImp::Project->get(1);
    ok($setup{project}, 'get project');
    $setup{submission} = RefImp::Project::Submission->create(
        project => $setup{project},
        phase => 3,
        directory => '/tmp',
    );
    ok($setup{submission}, 'create submission');

    $setup{expected_data} = {
        file => $setup{file},
        source => 'wugsc',
        seqname => 'HMPB-AAD13A05',
        localseqname => 'HMPB-AAD13A05',
        accession => 'AC999999',
        version => '1',
        gi => 1042705582,
        phase => 3,
        notes => 'New',
        crdate => '2016-07-07',
        update => '2016-07-07',
    };

};

subtest "from_file" => sub{
    plan tests => 4;

    $setup{report} = RefImp::Resources::Ncbi::SubmissionReport->from_file($setup{file});
    is_deeply($setup{report}->data, $setup{expected_data}, 'load report from file');
    is($setup{report}->project_name, $setup{report}->data->{localseqname}, 'report project_name');
    is($setup{report}->project, $setup{project}, 'report project');
    is($setup{report}->submission, $setup{submission}, 'report submission');

};

subtest "update submission" => sub{
    plan tests => 6;

    my $report = $setup{report};
    ok($report->update_submission, 'update submission');
    is($report->submission->accession_id, $setup{expected_data}->{accession}, 'set submission accession_id');

    $report->project(undef);
    ok(!$report->update_submission, 'update submission fails w/o project');
    like($report->error_message, qr/No project for/, 'correct error');
    $report->project($setup{project});

    $report->submission(undef);
    ok(!$report->update_submission, 'update submission fails w/o submission');
    like($report->error_message, qr/No submission for/, 'correct error');
    $report->submission($setup{submission});


};

done_testing();
