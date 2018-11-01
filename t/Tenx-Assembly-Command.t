#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;
use Test::Exception;
use Test::More tests => 2;

my %test = ( class => 'Tenx::Assembly::Command' );
subtest 'command classes' => sub{
    plan tests => 6;

    use_ok($test{class}) or die;
    ok(UR::Object::Type->get('Tenx::Assembly::Command::Create'), 'create command');
    ok(UR::Object::Type->get('Tenx::Assembly::Command::List'), 'list command');
    ok(UR::Object::Type->get('Tenx::Assembly::Command::Update'), 'update command');
    ok(UR::Object::Type->get('Tenx::Assembly::Command::Delete'), 'delete command');
    ok(!UR::Object::Type->get('Tenx::Assembly::Command::Copy'), 'no copy command');

};

subtest 'get_assembly' => sub{
    plan tests => 11;

    throws_ok(sub{ $test{class}->get_assembly; }, qr/but 2 were expected/, 'fails w/o param');

    my $id = UR::Object::Type->autogenerate_new_object_id_uuid;
    my $expected_url = '/data/assembly/SAMPLE1';
    my $expected_assembly = Tenx::Assembly->__define__(sample_name => 'SAMPLE1', url => $expected_url);

    my $assembly;
    lives_ok(sub{ $assembly = $test{class}->get_assembly(('A' x 32)); }, 'try to get no existing assembly by id');
    ok(!$assembly, 'no assembly for unknown id');
    lives_ok(sub{ $assembly = $test{class}->get_assembly($expected_assembly->id); }, 'get existing assembly by id');
    is($assembly, $expected_assembly, 'correct assembly');

    lives_ok(sub{ $assembly = $test{class}->get_assembly($expected_url); }, 'get existing assembly by url');
    is($assembly, $expected_assembly, 'correct assembly');

    lives_ok(sub{ $assembly = $test{class}->get_assembly('/data/assembly/SAMPLE2'); }, 'get non existing aassembly by url');
    ok($assembly, 'got assembly');
    isnt($assembly->id, $expected_assembly->id, 'correct assembly');
    is($assembly->sample_name, 'SAMPLE2', 'set assembly sample name');

};

done_testing();
