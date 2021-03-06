#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use Test::More tests => 3;

my %setup;
subtest 'setup' => sub{
    plan tests => 1;

    $setup{pkg} = 'RefImp::Project::Command::Submission::Report';
    use_ok($setup{pkg}) or die;


    my $project = RefImp::Project->get(1);
    my $user = RefImp::User->get(1);
    RefImp::Project::User->create(
        project => $project,
        user => $user,
        purpose => 'finisher',
    );
    push @{$setup{submissions}}, RefImp::Project::Submission->create(
        project => $project,
        directory => '/tmp',
        submitted_on => '2017-01-01',
        project_size => 101000,
    );

    $project = RefImp::Project->create(name => 'TESTER_22');
    $user = RefImp::User->create(name => 'gwbush');
    RefImp::Project::User->create(
        project => $project,
        user => $user,
        purpose => 'finisher',
    );
    push @{$setup{submissions}}, RefImp::Project::Submission->create(
        project => $project,
        directory => '/tmp',
        submitted_on => '2016-01-01',
        project_size => 202000,
    );
    
};

subtest 'general' => sub {
    plan tests => 2;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    my $report = $setup{pkg}->execute(submissions => $setup{submissions});
    ok($report->result, 'execute');


    my $expected_output = <<OUT;
Project       Finisher Date       Size  
-------       -------- ----       ----  
HMPB-AAD13A05 bobama   2017-01-01 101000
TESTER_22     gwbush   2016-01-01 202000
---
Number of Projects: 2
Total Size: 303000
OUT
    is($output, $expected_output, 'output is correct');

};

subtest 'finisher' => sub {
    plan tests => 2;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    my $report = $setup{pkg}->execute(submissions => $setup{submissions}, type => 'finisher');
    ok($report->result, 'execute');

    my $expected_output = <<OUT;
Project       Date       Size  
-------       ----       ----  
HMPB-AAD13A05 2017-01-01 101000
---
Finisher: bobama
Number of Projects: 1
Total Size: 101000

Project   Date       Size  
-------   ----       ----  
TESTER_22 2016-01-01 202000
---
Finisher: gwbush
Number of Projects: 1
Total Size: 202000
OUT
    is($output, $expected_output, 'output is correct');

};

done_testing();
