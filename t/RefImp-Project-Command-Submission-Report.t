#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 2;

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
    
};

subtest 'general' => sub {
    plan tests => 2;

    my $output;
    open local( *STDOUT), '>', \$output or die $!;
    my $report = $setup{pkg}->execute(submissions => $setup{submissions});
    ok($report->result, 'execute');


    my $expected_output = <<OUT;
Project       Finisher Date       Size  
-------       -------- ----       ----  
HMPB-AAD13A05 bobama   2017-01-01 101000
---
Number of Projects: 1
Total Size: 101000
OUT
    is($output, $expected_output, 'output is correct');

};

done_testing();
