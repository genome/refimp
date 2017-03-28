#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 2;

my $pkg = 'RefImp::Project::Submission';

my $submission;
subtest 'create' => sub {
    plan tests => 6;

    use_ok($pkg) or die;

    my $project = RefImp::Project->get(1);
    $submission = $pkg->create(
        accession_id => 'AC1111',
        directory => '/dev',
        phase => '3',
        project => $project,
    );
    ok($submission, 'create submission');

    ok($submission->accession_id, 'accession');
    ok($submission->directory, 'directory');
    ok($submission->phase, 'submitted_on set');
    ok($submission->submitted_on, 'submitted_on set');

};

subtest 'project' => sub{
    plan tests => 3;

    my $project = RefImp::Project->get(1);
    my @submissions = $project->submissions;
    is_deeply(\@submissions, [$submission], 'project submissions');

    is($submission->project, $project, 'project');
    is($submission->project_id, $project->id, 'project_id');

};

done_testing();
