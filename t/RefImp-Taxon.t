#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 4;

my $pkg = 'RefImp::Taxon';
use_ok($pkg) or die;
my $clone = RefImp::Clone->get(1);

subtest 'unknown taxon w/o clone' => sub {
    plan tests => 5;

    TestEnv::LimsRestApi::setup(species_name => 'unknown');
    my $unknown_taxon = $pkg->get_for_clone_name('BLAH');
    ok($unknown_taxon, 'got unknown taxon');
    is($unknown_taxon->species_name, 'unknown', 'species_name');
    is($unknown_taxon->species_latin_name, 'unknown', 'species_latin_name');
    is($unknown_taxon->species_short_name, 'unknown', 'species_short_name');
    is($unknown_taxon->chromosome, 'unknown', 'chromosome');

};

subtest 'unknown taxon w/ clone' => sub {
    plan tests => 5;

    TestEnv::LimsRestApi::setup(species_name => 'unknown');
    my $unknown_taxon = $pkg->get_for_clone_name($clone->name);
    ok($unknown_taxon, 'got unknown taxon');
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
    TestEnv::LimsRestApi::setup(%attributes);

    my $taxon = $pkg->get_for_clone_name($clone->name);
    ok($taxon, 'trichnella taxon');
    for my $attr ( keys %attributes ) { is($taxon->$attr, $attributes{$attr}, "trichnella $attr"); }
    is($taxon->species_short_name, 'trichinella', 'trichnella species_short_name');

};

done_testing();
