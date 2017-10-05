#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 4;

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


    $setup{file_without_submission} = File::Spec->join(
        TestEnv::test_data_directory_for_package($pkg),
        "wugsc20170615.0.pha454L20.phase3.fa2htgs.asn.ac4htgs",
    );

    $setup{expected_data_without_submission} = {
        file => $setup{file_without_submission},
        source => 'wugsc',
        seqname => 'CH17-454L20',
        localseqname => 'H_GD-454L20',
        accession => 'AC275671',
        version => '1',
        gi => '1207071914',
        phase => '3',
        notes => 'New',
        crdate => '2017-06-15',
        update => '2017-06-15',
    };

};

subtest "from_file with no project" => sub{
    plan tests => 5;

    my $report = RefImp::Resources::Ncbi::SubmissionReport->from_file($setup{file_without_submission});
    ok($report, 'loaded report from file');
    is_deeply($report->data, $setup{expected_data_without_submission}, 'data matches');
    is($report->project_name, $setup{expected_data_without_submission}->{localseqname}, 'report project_name');
    ok(!$report->project, 'report does not have a project');
    ok(!$report->submission, 'report does not have a submission');

};

subtest "from_file" => sub{
    plan tests => 5;

    $setup{report} = RefImp::Resources::Ncbi::SubmissionReport->from_file($setup{file});
    ok($setup{report}, 'loaded report from file');
    is_deeply($setup{report}->data, $setup{expected_data}, 'data matches');
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
