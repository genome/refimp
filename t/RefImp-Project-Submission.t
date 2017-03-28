#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 1;

my $pkg = 'RefImp::Project::Submission';

subtest 'basics' => sub {
    plan tests => 9;

    use_ok($pkg) or die;

    my $project = RefImp::Project->get(1);
    my $submission = $pkg->create(
        accession_id => 'AC1111',
        directory => '/dev',
        phase => '3',
        project => $project,
    );
    ok($submission, 'create submission');

    ok($submission->accession_id, 'accession');
    ok($submission->directory, 'directory');
    ok($submission->phase, 'submitted_on set');
    is($submission->project, $project, 'project');
    is($submission->project_id, $project->id, 'project_id');
    is($submission->project_name, $project->name, 'project_name');
    ok($submission->submitted_on, 'submitted_on set');

};

done_testing();
