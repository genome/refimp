package RefImp::Taxon;

use strict;
use warnings;

class RefImp::Taxon { 
    is => 'UR::Object',
    has => {
        species_name => { is => 'Text', default_value => 'unknown', },
        species_latin_name => { is => 'Text', default_value => 'unknown', },
        species_short_name => { is => 'Text', },
        chromosome => { is => 'Text', default_value => 'unknown', },
    },
};

my %species_short_names = (
    "a. thaliana"                  => "arabidopsis",
    "c. elegans"                   => "elegans",
    "C. remanei"                   => "remanei",
    "Caenorhabditis japonica"      => "japonica",
    "Caenorhabditis PB2801"        =>  "PB2801",
    "Callorhinchus milii"          => "elephantshark",
    "Cat"                          => "cat",
    "c_briggsae"                   => "briggsae",
    "Chlorocebus aethiops sabaeus" => "vervet",
    "Common Marmoset"              => "marmoset",
    "Gallus gallus"                => "chicken",
    "gorilla"                      => "gorilla",
    "Gray Short-Tailed Opossum"    => "Opossum",
    "Gray Short-Tailed Opossum"    => "opossum",
    "Lamprey"                      => "lamprey",
    "Macaque"                      => "macaque",
    "mouse spret/ei"               =>  "spretus",
    "Northern Tree Shrew"          => "shrew",
    "Phlebotomus papatasi"         => "sandfly",
    "platypus"                     => "plat",
    "Pristionchus pacificus"       => "Pristionchus",
    "Sumatran Orangutan"           => "orangutan",
    "Trichinella spiralis"         => "trichinella",
    "Western Painted Turtle"       => "turtle",
    "White-Cheeked Gibbon"         => "gibbon",
    "Zebra finch"                  => "zebrafinch",
);

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);

    $self->species_short_name(
        exists $species_short_names{$self->species_name}
        ? $species_short_names{$self->species_name}
        : $self->species_name
    );

    return $self;
}

1;

