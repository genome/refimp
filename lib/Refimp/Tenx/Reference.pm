package Refimp::Tenx::Reference;

use strict;
use warnings;

use Path::Class;

class Refimp::Tenx::Reference {
    table_name => 'tenx_references',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        directory => { is => 'Text', doc => 'File system location.', },
        name => { is => 'Text', doc => 'Short name of the reference.', },
        taxon => {
            is => 'Refimp::Taxon',
            id_by => 'taxon_id',
            doc => 'The reference taxon.',
        },
    },
    data_source => Refimp::Config::get('ds_mysql'),
};

sub __display_name__ { sprintf('%s (%s)', $_[0]->name, $_[0]->directory) }

sub __errors__ {
    my $self = shift;

    my @errors = $self->SUPER::__errors__;
    return @errors if @errors;

    push @errors, UR::Object::Tag->create(
        type => 'error',
        properties => [qw/ directory /],
        desc => 'Reference directory does not exist: '.$self->directory,
    ) if !-d $self->directory;

    for my $property (qw/ name directory /) {
        my @existing_refs = grep { $_->id ne $self->id } __PACKAGE__->get($property => $self->$property);
        push @errors, UR::Object::Tag->create(
            type => 'error',
            properties => [ $property ],
            desc => sprintf('Found existing reference with %s: %s', $property, join(',', map { $_->__display_name__} @existing_refs)),
        ) if @existing_refs;
    }

    @errors;
}

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->directory( dir($self->directory)->absolute->stringify );

    my @errors = $self->__errors__;
    $self->fatal_message( join("\n", map { $_->__display_name__ } @errors) ) if @errors;

    $self;
}

1;
