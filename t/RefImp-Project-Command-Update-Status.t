#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::Command::Update::Status';

my %setup;
subtest "setup" => sub{
    plan tests => 1;

    use_ok($pkg) or die;

    $setup{project} = RefImp::Project->get(1);
    $setup{project}->status('10X done');

};

subtest 'update' => sub{
    plan tests => 2;

    my $update = $pkg->execute(
        projects => [ $setup{project}, ],
        value => 'submitted',
    );
    ok($update->result, 'execute');

    is($setup{project}->status, 'submitted', 'set project status');

};

done_testing();
