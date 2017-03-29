#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Temp;
use Test::More tests => 3;

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

done_testing();
