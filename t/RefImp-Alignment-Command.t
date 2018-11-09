#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;
use Test::More tests => 1;

subtest 'command classes' => sub{
    plan tests => 6;

    use_ok('RefImp::Alignment::Command') or die;
    ok(UR::Object::Type->get('RefImp::Alignment::Command::Create'), 'create command');
    ok(UR::Object::Type->get('RefImp::Alignment::Command::List'), 'list command');
    ok(UR::Object::Type->get('RefImp::Alignment::Command::Update'), 'update command');
    ok(UR::Object::Type->get('RefImp::Alignment::Command::Delete'), 'delete command');
    ok(!UR::Object::Type->get('RefImp::Alignment::Command::Copy'), 'no copy command');

};

done_testing();
