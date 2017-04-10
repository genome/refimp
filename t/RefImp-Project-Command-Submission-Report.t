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
    push @{$setup{submissions}}, RefImp::Project::Submission->create(
        project => $project,
        directory => '/tmp',
        submitted_on => '2017-01-01',
    );
    
};

subtest 'execute' => sub {
    plan tests => 1;

    my $report = $setup{pkg}->execute(submissions => $setup{submissions});
    ok($report->result, 'execute');

};

done_testing();
