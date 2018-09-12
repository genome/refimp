#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;
use Test::More tests => 1;

subtest 'command classes' => sub{
    plan tests => 6;

    use_ok('Tenx::Alignment::Command') or die;
    ok(UR::Object::Type->get('Tenx::Alignment::Command::Create'), 'create command');
    ok(UR::Object::Type->get('Tenx::Alignment::Command::List'), 'list command');
    ok(UR::Object::Type->get('Tenx::Alignment::Command::Update'), 'update command');
    ok(UR::Object::Type->get('Tenx::Alignment::Command::Delete'), 'delete command');
    ok(!UR::Object::Type->get('Tenx::Alignment::Command::Copy'), 'no copy command');

};

done_testing();
