#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Sub::Install;
use Test::Exception;
use Test::More tests => 2;

my @projects;
subtest 'setup' => sub{
    plan tests => 2;

    use_ok('RefImp::Project::Command::BaseWithMany') or die;

    class BaseWithManyTest {
        is => 'RefImp::Project::Command::BaseWithMany',
    };

    push @projects, RefImp::Project->get(1);
    is(@projects, 1, 'got projects');

};

subtest '_execute_with_project' => sub{
    plan tests => 2;

    throws_ok(
        sub{ BaseWithManyTest->execute(projects => \@projects); },
        qr/Implement _execute_with_project\!/,
        'execute fails when _execute_with_project is not implemented',
    );

    Sub::Install::reinstall_sub({
            code => sub{ 1 },
            into => 'BaseWithManyTest',
            as => '_execute_with_project',
        });
    lives_ok(
        sub{ BaseWithManyTest->execute(projects => \@projects); },
        'implemented _execute_with_project',
    );

};

done_testing();
