#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 3;

my %setup;
subtest 'setup'=> sub{
    plan tests => 2;

    $setup{pkg} = 'RefImp::Project::Command::Submission::Form';
    use_ok($setup{pkg}) or die;

    $setup{project} = RefImp::Project->get(1);
    ok($setup{project}, 'got project');

};

my $submission;
subtest 'execute fails' => sub{
    plan tests => 3;

    my $cmd;
    throws_ok(
        sub{ $cmd = $setup{pkg}->execute(
               project => $setup{project},
            ); },
        qr/No submissions found for/,
        'execute submission form when no submission',
    );

    $setup{submission} = RefImp::Project::Submission->create(
        project => $setup{project},
        directory => '/blah',
    );
    throws_ok(
        sub{ $cmd = $setup{pkg}->execute(
               project => $setup{project},
            ); },
        qr/No directory for submission/,
        'execute submission form when no directory',
    );

    $setup{submission}->directory('/tmp');
    throws_ok(
        sub{ $cmd = $setup{pkg}->execute(
               project => $setup{project},
            ); },
        qr/No submit form file found for/,
        'execute submission form when no form',
    );

};

subtest 'execute' => sub{
    plan tests => 3;

    $setup{submission}->directory( TestEnv::test_data_directory_for_package($setup{pkg}) );

    my $cmd;
    lives_ok(
        sub{ $cmd = $setup{pkg}->execute(
               project => $setup{project},
            ); },
        'execute submission form',
    );
    ok($cmd->result, 'execute successful');
    ok(!$cmd->error_message, 'no error message');

};

done_testing();
