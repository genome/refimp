package RefImp::Taxon;

use strict;
use warnings 'FATAL';

use Params::Validate qw/ :types validate_pos /;

class RefImp::Taxon { 
    is => 'UR::Object',
    has => {
        species_name => { is => 'Text', default_value => 'unknown', },
        species_latin_name => { is => 'Text', default_value => 'unknown', },
        species_short_name => { is => 'Text', default_value => 'unknown', },
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

sub get_for_clone_name {
    my ($class, $clone_name) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    my $clone = RefImp::Clone->get(name => $clone_name);
    return $class->create if not $clone;

    my $species_name = RefImp::Resources::LimsRestApi->new->query($clone, 'species_name');
    my $self = $class->get(species_name => $species_name);
    return $self if $self;

    my %taxonomy;
    $taxonomy{species_name} = $species_name;
    for my $attribute (qw/ species_latin_name chromosome /) {
        $taxonomy{$attribute} = RefImp::Resources::LimsRestApi->new->query($clone, $attribute) // 'unknown';
    }

    $taxonomy{species_short_name} = ( exists $species_short_names{$species_name} )
    ? $species_short_names{ $taxonomy{species_name} }
    : $taxonomy{species_name};

    $class->create(%taxonomy);
}

1;

