#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use File::Compare;
use Sub::Install;
use Test::Exception;
use Test::More tests => 3;

use Carp;
$SIG{__DIE__} = sub{ Carp::confess(@_); };

my %setup;
subtest 'setup' => sub{
    plan tests => 1;

    $setup{pkg} = 'RefImp::Project::Command::Submit';
    use_ok($setup{pkg}) or die;

    $setup{project} = RefImp::Project->get(1);

    Sub::Install::reinstall_sub({
            code => sub { File::Spec->join(RefImp::Config::get('test_data_path'), 'analysis', 'templates', 'raw_human_template.sqn') },
            as => 'raw_sqn_template_for_taxon',
            into => 'RefImp::Clone::Submissions',
        });

    my $clone = RefImp::Clone->get(1);
    $setup{file_names_to_compare} = [
        RefImp::Clone::Submissions->submit_info_yml_file_name_for_clone($clone),
        RefImp::Clone::Submissions->submit_form_file_name_for_clone($clone),
        join('.', $clone->name, 'whole', 'contig'),
        join('.', $clone->name, 'seq'),
    ];

   $setup{ftp} = RefImp::Test::Factory->setup_test_ftp;

    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    RefImp::Config::set('analysis_directory', $tempdir);

    RefImp::Config::set('ncbi_ftp_host', 'ftp-host');
    RefImp::Config::set('ncbi_ftp_user', 'ftp-user');
    RefImp::Config::set('ncbi_ftp_password', 'ftp-password');

    TestEnv::Clone::setup_test_lims_rest_api;
    
    Sub::Install::reinstall_sub({
            code => sub{ $_[0]->overlaps([]); 1; },
            into => 'RefImp::Project::Command::Overlaps',
            as => 'set_overlaps',
        });

};

subtest 'cannot submit project with incorrect status' => sub{
    plan tests => 2;

    is($setup{project}->status('finish_start'), 'finish_start', 'set project status to finish_start');
    throws_ok(sub{ $setup{pkg}->execute(project => $setup{project}); }, qr/Project /, 'fails w/ incorrect project status');

};

subtest 'submit' => sub{
    plan tests => 12;

    my $project = $setup{project};
    $project->status('presubmitted');
    my $cmd = $setup{pkg}->create(project => $setup{project});
    $setup{ftp}->mock('size', sub{ -s $cmd->asn_path });
    ok($cmd, 'create');
    ok($cmd->execute, 'execute');

    is($cmd->project, $project, 'project');
    is($project->status, 'submitted', 'set project status');

    ok($cmd->staging_directory, 'set staging_directory');
    ok($cmd->submit_info, 'set submit_info');
    my $analysis_subdirectory = $cmd->analysis_subdirectory;
    ok($analysis_subdirectory, 'set analysis_subdirectory');

    my $test_data_path = TestEnv::test_data_directory_for_package($setup{pkg});
    for my $file_name ( @{$setup{file_names_to_compare}} ) {
        my $path = File::Spec->join($analysis_subdirectory, $file_name);
        my $expected_path = File::Spec->join($test_data_path, $file_name);
        is(File::Compare::compare($path, $expected_path), 0, "$file_name saved");
    }
    ok(-s $cmd->asn_path, 'asn_path saved');

};

done_testing();
