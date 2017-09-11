#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 1;

subtest 'update taxonomy' => sub{
    plan tests => 10;

    my $pkg = 'Refimp::Project::Command::Update::Taxonomy';
    use_ok($pkg) or die;

    my $project = Refimp::Project->get(1);
    ok($project, 'got project');
    my $current_taxonomy = $project->taxonomy;
    ok($current_taxonomy, 'got project taxonomy');

    my $new_taxon = Refimp::Taxon->create(name => 'the foo', species_name => 'foo bar');
    ok($new_taxon, 'create new taxon');

    my $cmd;
    lives_ok(
        sub{
            $cmd = $pkg->execute(
                projects => [$project],
                taxon => $new_taxon,
                chromosome => 8,
            );
        },
        '',
    );
    ok($cmd->result, 'execute');

    my $taxonomy = $project->taxonomy;
    ok($taxonomy, 'got taxonomy') or die;
    isnt($taxonomy, $current_taxonomy, 'created new project taxonomy');
    is($taxonomy->taxon, $new_taxon, 'correct taxon');
    is($taxonomy->chromosome, 8, 'correct chromosome');

};

done_testing();
