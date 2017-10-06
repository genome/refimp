#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use lib '.';


use TestEnv;

use File::Temp;
use Test::Exception;
use Test::More tests => 3;

use_ok('RefImp::Project::Command::Create') or die;
my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

subtest 'create w/o taxon' => sub{
    plan tests => 8;

    my $name = "TEST_PROJECT";
    my $project = RefImp::Project->get(name => $name);
    ok(!$project, 'project does not exist');

    my $taxon = RefImp::Taxon->create(name => 'unknown', species_name => 'unknown');
    ok($taxon, 'create unknown taxon');

    my $cmd;
    lives_ok(
        sub{ $cmd = RefImp::Project::Command::Create->execute(
                names => [$name],
                directory => $tmpdir,
            ); },
        'execute project create',
    );
    ok($cmd->result, 'execute successful');

    $project = RefImp::Project->get(name => $name);
    ok($project, 'project created');
    is($project->status, 'prefinish_start', 'status set');
    ok(-d $project->directory, 'created and set directory');

    ok(UR::Context->commit, 'commit');

};

subtest 'from file existing updates' => sub{
    plan tests => 10;

    my $name = "TEST_PROJECT";
    my $project = RefImp::Project->get(name => $name);
    ok($project, 'project exists');
    is($project->status, 'prefinish_start', 'status');

    my $taxon = RefImp::Taxon->get(1);
    ok($taxon, 'got taxon');

    my $file = File::Spec->join($tmpdir, 'project_names');
    my $fh = IO::File->new($file, 'w');
    $fh->print("$name\n");
    $fh->close;

    my $cmd;
    lives_ok(
        sub{ $cmd = RefImp::Project::Command::Create->execute(
                names => [$name],
                status => 'unknown',
                taxon => $taxon,
                chromosome => 2,
            ); },
        'execute when project exists',
    );
    ok($cmd->result, 'execute successful');
    is($project->status, 'unknown', 'status updated');
    my $taxonomy = $project->taxonomy;
    ok($taxonomy, 'set project taxonomy');
    is($taxonomy->taxon, $taxon, 'correct taxon');
    is($taxonomy->chromosome, 2, 'correct chromosome');

    ok(UR::Context->commit, 'commit');

};

done_testing();
