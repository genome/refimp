#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;
use Test::Exception;
use Test::More tests => 3;

my $pkg = 'RefImp::Project::Command::Update::CloneType';

my %setup;
subtest "setup" => sub{
    plan tests => 1;

    use_ok('RefImp::Project::Command');

    $setup{project} = RefImp::Project->get(1);
    $setup{project}->clone_type('yac');

};

subtest 'failures' => sub{
    plan tests => 7;

    my $err;
    open local(*STDERR), '>', \$err or die $!;

    my $cmd = $pkg->create(projects => [ $setup{project} ]);
    ok(!$pkg->execute, 'execute fails w/o clone_type');
    like($err, qr/'value'/, 'correct error');

    $err = '';
    $cmd = $pkg->create(value => 'bac');
    ok(!$cmd->execute, 'execute fails w/o projects');
    like($err, qr/'projects'/, 'correct error');

    $err = '';
    $cmd = $pkg->create(projects => [ $setup{project} ], value => 'blah');
    ok(!$cmd->execute, 'execute fails w/ invalid clone_type');
    like($err, qr/valid values/, 'correct error');

    is($setup{project}->clone_type, 'yac', 'did not set project clone_type');

};

subtest 'update' => sub{
    plan tests => 2;

    my $update = $pkg->execute(
        projects => [ $setup{project}, ],
        value => 'bac',
    );
    ok($update->result, 'execute');

    is($setup{project}->clone_type, 'bac', 'set project clone_type');

};

done_testing();
