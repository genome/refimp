#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Compare;
use Sub::Install;
use Test::Exception;
use Test::More tests => 2;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    $test{pkg} = 'RefImp::Project::Command::Submission::Resubmit';
    use_ok($test{pkg}) or die;

    $test{data_dir} = TestEnv::test_data_directory_for_package('RefImp::Project::Command::Submission::Submit');
    $test{submission} = RefImp::Project::Submission->create(
        project => RefImp::Project->get(1),
        directory => $test{data_dir},
        submitted_on => '2000-01-01',
        phase => 3,
    );
    ok($test{submission}, 'create submission');
    $test{submission}->project->status('presubmitted');

    Sub::Install::reinstall_sub({
            code => sub { File::Spec->join(RefImp::Config::get('test_data_path'), 'analysis', 'templates', 'raw_human_template.sqn') },
            as => 'raw_sqn_template_for_taxon',
            into => 'RefImp::Project::Submission',
        });

    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    RefImp::Config::set('analysis_directory', $tempdir);

    $test{ftp} = TestEnv::NcbiFtp->setup;
    RefImp::Config::set('ncbi_ftp_host', 'ftp-host');
    RefImp::Config::set('ncbi_ftp_user', 'ftp-user');
    RefImp::Config::set('ncbi_ftp_password', 'ftp-password');

    TestEnv::LimsRestApi::setup;

};

subtest 'submit' => sub{
    plan tests => 18;

    my $from_submission = $test{submission};
    my @submissions = $from_submission->project->submissions;
    is(@submissions, 1, 'project has one submission');

    my $cmd = $test{pkg}->create(from_submission => $from_submission);
    ok($cmd, 'create');
    $test{ftp}->mock('size', sub{ -s $cmd->asn_path });
    ok($cmd->execute, 'execute');

    my $submission = $cmd->submission;
    ok($submission, 'created and set submission');
    ok($submission->directory, 'submission directory');
    ok($submission->submitted_on, 'submission submitted_on');
    is($submission->project_size, 1413, 'submission project_size');

    ok($cmd->asn_path, 'set asn_path');
    ok($cmd->staging_directory, 'set staging_directory');
    ok($cmd->submit_info, 'set submit_info');

    @submissions = $submission->project->submissions;
    is(@submissions, 2, 'created submission');

    my $project = $submission->project;
    is($project, $test{submission}->project, 'submission project');
    is($project->status, 'submitted', 'project status is still submitted');

    my @file_names_to_compare = (
        $submission->submit_info_yml_file_name,
        $submission->submit_form_file_name,
        join('.', $project->name, 'whole', 'contig'),
        join('.', $project->name, 'seq'),
    );
    for my $file_name ( @file_names_to_compare ) {
        my $path = File::Spec->join($submission->directory, $file_name);
        my $expected_path = File::Spec->join($test{data_dir}, $file_name);
        is(File::Compare::compare($path, $expected_path), 0, "$file_name saved");
    }
    ok(-s $cmd->asn_path, 'asn_path saved');

};

done_testing();
