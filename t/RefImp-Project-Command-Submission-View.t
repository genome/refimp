#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 2;

my %setup;
subtest 'setup'=> sub{
    plan tests => 3;

    $setup{pkg} = 'RefImp::Project::Command::Submission::View';
    use_ok($setup{pkg}) or die;

    $setup{project} = RefImp::Project->get(1);
    ok($setup{project}, 'got project');

    $setup{submission} = RefImp::Project::Submission->create(
        project => $setup{project},
        directory => '/blah',
        project_size => 111111,
        phase => 3,
    );
    ok($setup{submission}, 'create submission');

};

subtest 'execute' => sub{
    plan tests => 6;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $setup{pkg}->execute(submission => $setup{submission}); }, 'execute submission w/o directroy');
    like($output, qr/Submission directory not defined or does not exist/, 'correct output');

    $output = '';
    $setup{submission}->directory('/tmp');
    lives_ok(sub{ $setup{pkg}->execute(submission => $setup{submission}); }, 'execute submission w/o form');
    like($output, qr/No submission form in directory/, 'correct output');

    $setup{submission}->directory( TestEnv::test_data_directory_for_package($setup{pkg}) );
    $output = '';
    lives_ok( sub{ $setup{pkg}->execute(submission => $setup{project}); }, 'execute submission w/ form');
    like($output, qr/1\) CLONE NAME IS/, 'correct output');

};

done_testing();
