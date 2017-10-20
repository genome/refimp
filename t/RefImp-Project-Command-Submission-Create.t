#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use Test::Exception;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::Command::Submission::Create';
subtest 'create' => sub{
    plan tests => 12;

    use_ok($pkg) or die;

    my $project = RefImp::Project->get(1);
    ok($project, 'got project');

    my @submissions = $project->submissions;
    ok(!@submissions, 'project does not have submissions');

    my $cmd;
    lives_ok(
        sub{ $cmd = $pkg->execute(
                project => $project,
                accession_id => 'AC000000',
                directory => '/tmp',
                phase => 3,
                submitted_on => '2001-01-20',
            ); },
        'execute submission create',
    );
    ok($cmd->result, 'execute successful');

    @submissions = $project->submissions;
    is(@submissions, 1, 'created submission');
    is($submissions[0]->project, $project, 'set submission project');
    is($submissions[0]->accession_id, 'AC000000', 'set submission accession_id');
    is($submissions[0]->directory, '/tmp', 'set submission directory');
    is($submissions[0]->phase, 3, 'set submission phase');
    like($submissions[0]->submitted_on, qr/^2001-01-20/, 'set submitted_on');

    ok(UR::Context->commit, 'commit');

};

subtest 'create_from_directory' => sub{
    plan tests => 11;

    my $project = RefImp::Project->get(1);
    ok($project, 'got project');

    my @submissions = $project->submissions;
    is(@submissions, 1, 'project has 1 submission');

    my $directory = File::Spec->join(TestEnv::test_data_directory_for_package($pkg), '20010203');
    my $cmd;
    lives_ok(
        sub{ $cmd = $pkg->execute(
                project => $project,
                directory => $directory,
                create_from_directory => 1,
            ); },
        'execute submission create from directory',
    );
    ok($cmd->result, 'execute successful');

    @submissions = $project->submissions(-order_by => 'submitted_on');
    is(@submissions, 2, 'created submission');
    ok(!$submissions[1]->accession_id, 'no submission accession_id');
    is($submissions[1]->directory, $directory, 'set submission directory');
    is($submissions[1]->project, $project, 'set submission project');
    is($submissions[1]->phase, 3, 'set submission phase');
    like($submissions[1]->submitted_on, qr/^2001-02-03/, 'set submitted_on');

    ok(UR::Context->commit, 'commit');

};

done_testing();
