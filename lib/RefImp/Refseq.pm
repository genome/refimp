package RefImp::Refseq;

use strict;
use warnings 'FATAL';

use Path::Class;

class RefImp::Refseq {
    table_name => 'refseqs',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        name => { is => 'Text', doc => 'Short name of the refseq.', },
        taxon => { is => 'RefImp::Taxon', id_by => 'taxon_id', doc => 'The refseq taxon.', },
        url => { is => 'Text', doc => 'File system location.', },
    },
    data_source => RefImp::Config::get('refimp_ds'),
};

sub __display_name__ { sprintf('%s (%s)', $_[0]->name, $_[0]->url) }

sub __errors__ {
    my $self = shift;

    my @errors = $self->SUPER::__errors__;
    return @errors if @errors;

    for my $property (qw/ name url /) {
        my @existing_refs = grep { $_->id ne $self->id } __PACKAGE__->get($property => $self->$property);
        push @errors, UR::Object::Tag->create(
            type => 'error',
            properties => [ $property ],
            desc => sprintf('Found existing refseq with %s: %s', $property, join(',', map { $_->__display_name__} @existing_refs)),
        ) if @existing_refs;
    }

    @errors;
}

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->url( dir($self->url)->absolute->stringify );

    my @errors = $self->__errors__;
    $self->fatal_message( join("\n", map { $_->__display_name__ } @errors) ) if @errors;

    $self;
}

1;
