#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;
use Test::More tests => 1;

subtest 'command classes' => sub{
    plan tests => 6;

    use_ok('Tenx::Refseq::Command') or die;
    ok(UR::Object::Type->get('Tenx::Refseq::Command::Create'), 'create command');
    ok(UR::Object::Type->get('Tenx::Refseq::Command::List'), 'list command');
    ok(UR::Object::Type->get('Tenx::Refseq::Command::Update'), 'update command');
    ok(UR::Object::Type->get('Tenx::Refseq::Command::Delete'), 'delete command');
    ok(!UR::Object::Type->get('Tenx::Refseq::Command::Copy'), 'no copy command');

};

done_testing();
