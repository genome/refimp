#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my %test;
subtest "setup" => sub{
    plan tests => 3;

    $test{pkg} = 'Refimp::Project::Command::Update::MyStatus';
    use_ok($test{pkg}) or die;

    $test{project} = Refimp::Project->get(1);
    ok($test{project}, 'got project');

    $test{user} = Refimp::User->get(1);
    ok($test{user}, 'got user');

};

subtest 'execute fails' => sub{
    plan tests => 3;

    my %params = (
        project => $test{project},
        value => 'STATUS',
    );
    {
        local $ENV{USER} = undef;
        throws_ok(sub{ $test{pkg}->execute(%params); }, qr/No ENV user set/, 'execute fails when user not given and no env user');
    };

    throws_ok(sub{ $test{pkg}->execute(%params); }, qr/No user found for/, 'execute fails when user not given and no db user for env user');

    $params{user} = $test{user};
    throws_ok(sub{ $test{pkg}->execute(%params); }, qr/No project finisher found/, 'execute fails w/o finisher');

};

subtest 'execute' => sub{
    plan tests => 4;

    my $project_finisher = Refimp::Project::User->__define__(
        project => $test{project},
        user => $test{user},
        purpose => 'finisher',
    );
    ok($project_finisher, 'create project finisher');

    my $my_status = 'Need to look at tandem at 10384';
    my $update = $test{pkg}->execute(
        project => $test{project},
        user => $test{user},
        value => $my_status,
    );
    ok($update->result, 'execute');

    is($project_finisher->status, $my_status, 'set project_finisher status');
    is($test{project}->my_status, $my_status, 'correct my_status');

};

done_testing();
