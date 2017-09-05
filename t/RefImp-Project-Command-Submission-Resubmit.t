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

    $test{submission} = RefImp::Project::Submission->create(
        project => RefImp::Project->get(1),
        directory => TestEnv::test_data_directory_for_package('RefImp::Project::Command::Submission::Submit');
        phase => 3,
    );
    ok($test{submission}, 'create submission');

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
    plan tests => 15;

    my $project = $test{project};
    $project->status('presubmitted');

    my @submissions = $project->submissions;
    is(@submissions, 0, 'project has not submissions');

    my $cmd = $test{pkg}->create(project => $test{project});
    $test{ftp}->mock('size', sub{ -s $cmd->asn_path });
    ok($cmd, 'create');
    ok($cmd->execute, 'execute');

    is($cmd->project, $project, 'project');
    is($project->status, 'submitted', 'set project status');

    ok($cmd->staging_directory, 'set staging_directory');
    ok($cmd->submit_info, 'set submit_info');

    @submissions = $project->submissions;
    is(@submissions, 1, 'created submission');
    is($submissions[0]->project, $project, 'submission project');
    is($submissions[0]->project_size, 1413, 'submission project_size');

    my @file_names_to_compare = (
        $submissions[0]->submit_info_yml_file_name,
        $submissions[0]->submit_form_file_name,
        join('.', $test{project}->name, 'whole', 'contig'),
        join('.', $test{project}->name, 'seq'),
    );
    my $test_data_path = TestEnv::test_data_directory_for_package($test{pkg});
    for my $file_name ( @file_names_to_compare ) {
        my $path = File::Spec->join($submissions[0]->directory, $file_name);
        my $expected_path = File::Spec->join($test_data_path, $file_name);
        is(File::Compare::compare($path, $expected_path), 0, "$file_name saved");
    }
    ok(-s $cmd->asn_path, 'asn_path saved');

};

done_testing();
