#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Spec;
use File::Temp;
use Test::Exception;
use Test::More tests => 5;

my $pkg = 'RefImp::Project::Submission';

my $submission;
subtest 'create' => sub {
    plan tests => 7;

    use_ok($pkg) or die;

    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    RefImp::Config::set('analysis_directory', $tempdir);

    my $project = RefImp::Project->get(1);
    $submission = $pkg->create(
        accession_id => 'AC1111',
        phase => '3',
        project => $project,
    );
    ok($submission, 'create submission');

    ok($submission->accession_id, 'accession');
    ok($submission->phase, 'submitted_on set');
    ok($submission->submitted_on, 'submitted_on set');

    ok($submission->directory, 'directory');
    my $expected_directory = File::Spec->join($tempdir, $project->taxon->species_short_name, lc($project->name), '\d{8}');
    like($submission->directory, qr/$expected_directory/, 'directory named correctly');

};

subtest 'create_from_directory' => sub{
    plan tests => 20;

    throws_ok(sub{ $pkg->create_from_directory(); }, qr/No directory specified to create submission record from/, 'create_from_directory fails w/o directory');
    throws_ok(sub{ $pkg->create_from_directory('/blah'); }, qr/Directory to create submission record from does not exist/, 'create_from_directory fails w/ non existing directory');

    my $test_data_directory = TestEnv::test_data_directory_for_package($pkg);
    throws_ok(sub{ $pkg->create_from_directory($test_data_directory); }, qr/because there is no submit info/, 'create_from_directory fails w/o submit info');

    my $directory = File::Spec->join($test_data_directory, '20010101');
    throws_ok(sub{ $pkg->create_from_directory($directory); }, qr/Failed to get project for/, 'create_from_directory fails w/o project');

    my $project = RefImp::Project->create(name => 'H_NH0094P19');

    lives_ok(sub{ $pkg->create_from_directory($directory); }, 'create_from_directory w/ legacy submit info');
    my @submissions = $project->submissions;
    is(@submissions, 1, 'created submission');
    is($submissions[0]->accession_id, 'AC231845', 'submission accession_id');
    is($submissions[0]->directory, $directory, 'submission directory');
    is($submissions[0]->phase, '3', 'submission phase');
    is($submissions[0]->project, $project, 'submission project');
    is($submissions[0]->project_size, 162249, 'submission project_size');
    is($submissions[0]->submitted_on, '2001-01-01', 'submission submitted_on');

    $directory =  File::Spec->join($test_data_directory, 'no-date-dir');
    lives_ok(sub{ $pkg->create_from_directory($directory); }, 'create_from_directory w/ legacy submit info');
    @submissions = $project->submissions;
    is(@submissions, 2, 'created submission');
    is($submissions[1]->accession_id, 'AC231845', 'submission accession_id');
    is($submissions[1]->directory, $directory, 'submission directory');
    is($submissions[1]->phase, '3', 'submission phase');
    is($submissions[1]->project, $project, 'submission project');
    is($submissions[1]->project_size, 162249, 'submission project_size');
    ok($submissions[1]->submitted_on, 'submission submitted_on');

};

subtest 'project' => sub{
    plan tests => 3;

    my $project = RefImp::Project->get(1);
    my @submissions = $project->submissions;
    is_deeply(\@submissions, [$submission], 'project submissions');

    is($submission->project, $project, 'project');
    is($submission->project_id, $project->id, 'project_id');

};

subtest 'form' => sub{
    plan tests => 3;

    my $project = $submission->project;
    my $expected_submit_form_file_name = join('.', $project->name, 'submit', 'form');
    is($submission->submit_form_file_name, $expected_submit_form_file_name, 'submit_form_file_name');
    is($submission->submit_form_file, File::Spec->join($submission->directory, $expected_submit_form_file_name), 'submit_form_file');
    is($submission->legacy_submit_form_file, File::Spec->join($submission->directory,'README'), 'legacy_submit_form_file');

};

subtest 'files' => sub{
    plan tests => 3;

    is($submission->submit_info_yml_file_name, join('.', $submission->project->name, 'submit', 'yml'), 'submit_form_file_name');

    my $analysis_directory = RefImp::Config::get('analysis_directory');
    is(
        $submission->raw_sqn_template_for_taxon($submission->project->taxon),
        File::Spec->join($analysis_directory, 'templates', 'raw_'.$submission->project->taxon->species_short_name.'_template.sqn'),
        'raw_sqn_template_for_taxon',
    );

    is(
        $submission->sequence_file_name,
        join('.', $submission->project->name, 'seq'),
        'whole_sequence_file_name',
    );

};

done_testing();
