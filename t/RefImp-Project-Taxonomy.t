#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::Taxonomy';
my ($project, $taxon);

subtest 'setup' => sub{
    plan tests => 3;

    use_ok($pkg) or die;

    $project = RefImp::Project->create(name => 'McProject');
    ok($project, 'create project');
    $taxon = RefImp::Taxon->create(name => 'McTaxon', species_name => 'taxon');
    ok($taxon, 'create taxon');

};

subtest 'create' => sub{
    plan tests => 8;

    my $taxonomy = $pkg->create(
        project => $project,
        taxon => $taxon,
        chromosome => '7',
    );
    ok($taxonomy, 'create project taxonomy');
    is($taxonomy->project, $project, 'project');
    is($taxonomy->taxon, $taxon, 'taxon');
    is($taxonomy->chromosome, '7', 'chromsome');
    is($taxonomy->common_name, $taxon->name, 'common_name');
    is($taxonomy->species_name, $taxon->species_name, 'species_name');
    is($taxonomy->__display_name__, sprintf('%s chromosome %s', $taxonomy->taxon->__display_name__, $taxonomy->chromosome), '__display_name__');

    ok(UR::Context->commit, 'commit');
};

done_testing();
