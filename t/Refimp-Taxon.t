#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 1;

subtest 'basics' => sub {
    plan tests => 7;

    use_ok('Refimp::Taxon') or die;

    my $taxon = Refimp::Taxon->get(name => 'human');
    ok($taxon, 'got taxon');
    is($taxon->name, 'human', 'name');
    is($taxon->species_name, 'homo sapiens', 'species_name');
    is($taxon->species_short_name, 'human', 'species_short_name');
    ok($taxon->strain_name('NA'), 'strain_name');

    is($taxon->__display_name__, sprintf('%s (%s %s)', $taxon->name, ucfirst($taxon->species_name), $taxon->strain_name), '__display_name__');

};

done_testing();
