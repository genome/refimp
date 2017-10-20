#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use Test::Exception;
use Test::More tests => 1;


subtest 'create' => sub{
    plan tests => 9;

    use_ok('RefImp::Taxon::Command::Create') or die;

    my $name = "testy";
    my $taxon = RefImp::Taxon->get(name => $name);
    ok(!$taxon, 'taxon does not exist');

    my $cmd;
    lives_ok(
        sub{ $cmd = RefImp::Taxon::Command::Create->execute(
                name => $name,
                species_name => 'Testy McTesterson',
                strain_name => 'FaCe',
            ); },
        'execute taxon create',
    );
    ok($cmd->result, 'execute successful');

    $taxon = RefImp::Taxon->get(name => $name);
    ok($taxon, 'taxon created');
    is($taxon->name, $name, 'set name');
    is($taxon->species_name, 'testy mctesterson', 'set name');
    is($taxon->strain_name, 'face', 'set strain_name');

    ok(UR::Context->commit, 'commit');

};

done_testing();
