package RefImp::Taxon;


use strict;
use warnings 'FATAL';

class RefImp::Taxon { 
    table_name => 'taxa',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        name => { is => 'Text', },
        species_name => { is => 'Text', },
    },
    has_optional => {
        strain_name => { is => 'Text', },
    },
    has_transient => {
        species_short_name => { is => 'Text', },
    },
    data_source => RefImp::Config::get('refimp_ds'),
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

sub __display_name__ {
    sprintf('%s (%s%s)', $_[0]->name, ucfirst($_[0]->species_name), ( $_[0]->strain_name ? ' '.$_[0]->strain_name : '' ));
}

sub get {
    my $class = shift;

    my $self = $class->SUPER::get(@_);
    return if not $self;

    $self->_add_species_short_name;

    $self;
}

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->_add_species_short_name;

    $self;
}

sub _add_species_short_name {
    my $self = shift;
    my $species_name = $self->species_name;
    $self->species_short_name( $species_short_names{$species_name} || $self->name );
}

1;

