#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

my $pkg = 'RefImp::Project::StatusHistory';
subtest 'basics' => sub{
    plan tests => 7;

    use_ok($pkg) or die;

    my $project = RefImp::Project->create(name => 'Testy McTesterson');
    ok($project, 'create project');

    my $psh = RefImp::Project::StatusHistory->create(
        project => $project,
        project_status => 'new',
    );
    ok($psh, 'create psh');
    is($psh->project, $project, 'psh project');
    is($psh->project_status, 'new', 'psh stautus');
    is($psh->project_status, $project->status, 'set project stautus');
    ok($psh->status_date, 'psh status_date');

};

done_testing();
