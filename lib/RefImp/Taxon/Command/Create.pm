package RefImp::Taxon::Command::Create;

use strict;
use warnings;

class RefImp::Taxon::Command::Create { 
    is => 'Command::V2',
    has_input => {
        name => {
            is => 'Text',
            doc => 'Common name of the taxon.',
        },
        species_name => {
            is => 'Text',
            doc => 'The full species name for the taxon.',
        },
    },
    has_optional_input => {
        strain_name => {
            is => 'Text',
            doc => 'Strain name, if applicable, for the taxon.',
        },
    },
    doc => 'create a taxon',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 
    $self->status_message('Create taxon...');

    my $name = lc($self->name);
    my $taxon = RefImp::Taxon->get(name => $name);
    $self->fatal_message('Found existing taxon: %s', $taxon->__display_name__) if $taxon;

    my %params = map { $_ => lc($self->$_) } grep { defined $self->$_ } (qw/ name species_name strain_name /);
    $self->status_message("Taxon params:\n%s---\n", YAML::Dump(\%params));
    $taxon = RefImp::Taxon->create(%params);
    $self->fatal_message('Failed to create taxon!') if !$taxon;
    $self->status_message('Created taxon %s', $taxon->__display_name__);

    1;
}

1;
