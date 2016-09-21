#!/usr/bin/env perl5.12.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 3;

my $pkg = 'RefImp::Clone::Taxon';
use_ok($pkg) or die;

subtest 'unknown taxon' => sub {
    plan tests => 5;

    my $unknown_taxon = $pkg->create;
    ok($unknown_taxon, 'creatre unknown taxon');
    is($unknown_taxon->species_name, 'unknown', 'species_name');
    is($unknown_taxon->species_latin_name, 'unknown', 'species_latin_name');
    is($unknown_taxon->species_short_name, 'unknown', 'species_short_name');
    is($unknown_taxon->chromosome, 'unknown', 'chromosome');

};

subtest 'taxon' => sub {
    plan tests => 5;

    my %attributes = (
        species_name => 'Trichinella spiralis',
        species_latin_name => 'Trichinella spiralis',
        chromosome => '1a',
    );
    my $taxon = $pkg->create(%attributes);
    ok($taxon, 'trichnella taxon');
    for my $attr ( keys %attributes ) { is($taxon->$attr, $attributes{$attr}, "trichnella $attr"); }
    is($taxon->species_short_name, 'trichinella', 'trichnella species_short_name');

};

done_testing();
