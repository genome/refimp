#!/usr/bin/env perl5.10.1

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

    $project = RefImp::Project->get(1);
    ok($project, 'got project');
    $taxon = RefImp::Taxon->get(1);
    ok($taxon, 'got taxon');

};

subtest 'create' => sub{
    plan tests => 6;

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

};

done_testing();
