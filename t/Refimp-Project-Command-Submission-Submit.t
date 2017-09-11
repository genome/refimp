#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Compare;
use Sub::Install;
use Test::Exception;
use Test::More tests => 3;

my %setup;
subtest 'setup' => sub{
    plan tests => 2;

    $setup{pkg} = 'Refimp::Project::Command::Submission::Submit';
    use_ok($setup{pkg}) or die;
    use_ok('Refimp::Project::Submission') or die;

    $setup{project} = Refimp::Project->get(1);

    Sub::Install::reinstall_sub({
            code => sub { File::Spec->join(Refimp::Config::get('test_data_path'), 'analysis', 'templates', 'raw_human_template.sqn') },
            as => 'raw_sqn_template_for_taxon',
            into => 'Refimp::Project::Submission',
        });

   $setup{ftp} = TestEnv::NcbiFtp->setup;

    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    Refimp::Config::set('analysis_directory', $tempdir);

    Refimp::Config::set('ncbi_ftp_host', 'ftp-host');
    Refimp::Config::set('ncbi_ftp_user', 'ftp-user');
    Refimp::Config::set('ncbi_ftp_password', 'ftp-password');

    TestEnv::LimsRestApi::setup;

};

subtest 'cannot submit project with incorrect status' => sub{
    plan tests => 2;

    is($setup{project}->status('finish_start'), 'finish_start', 'set project status to finish_start');
    throws_ok(sub{ $setup{pkg}->execute(project => $setup{project}); }, qr/Project /, 'fails w/ incorrect project status');

};

subtest 'submit' => sub{
    plan tests => 15;

    my $project = $setup{project};
    $project->status('presubmitted');

    my @submissions = $project->submissions;
    is(@submissions, 0, 'project has not submissions');

    my $cmd = $setup{pkg}->create(project => $setup{project});
    $setup{ftp}->mock('size', sub{ -s $cmd->asn_path });
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
        join('.', $setup{project}->name, 'whole', 'contig'),
        join('.', $setup{project}->name, 'seq'),
    );
    my $test_data_path = TestEnv::test_data_directory_for_package($setup{pkg});
    for my $file_name ( @file_names_to_compare ) {
        my $path = File::Spec->join($submissions[0]->directory, $file_name);
        my $expected_path = File::Spec->join($test_data_path, $file_name);
        is(File::Compare::compare($path, $expected_path), 0, "$file_name saved");
    }
    ok(-s $cmd->asn_path, 'asn_path saved');

};

done_testing();
