package RefImp::Assembly;

use strict;
use warnings 'FATAL';

class RefImp::Assembly {
    table_name => 'assemblies',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        name => {
            is => 'Text',
            doc => 'Name for the assembly.',
        },
        tech => { is => 'Text', doc => 'The technology that created the assembly. Ex: pacbio, tenx, phrap, etc.' },
        url => { is => 'Text', doc => 'Assembly location: file system, cloud.', },
    },
    has_optional => {
        reads => {
            is => 'RefImp::Reads',
            id_by => 'reads_id',
            doc => 'The reads that are assembled.',
        },
        status => {
            is => 'Text',
            doc => 'The status of the assembly: running, succeeded, failed, etc.',
        },
        taxon => {
            is => 'RefImp::Taxon',
            id_by => 'taxon_id',
            doc => 'Assembly taxon.',
        },
    },
    data_source => RefImp::Config::get('refimp_ds'),
};

sub __display_name__ { sprintf('%s (%s)', $_[0]->url, $_[0]->id) }

sub __errors__ {
    my $self = shift;

    my @errors = $self->SUPER::__errors__;
    return @errors if @errors;

    my @existing_assemblies = grep { $_->id ne $self->id } __PACKAGE__->get(url => $self->url);
    push @errors, UR::Object::Tag->create(
        type => 'error',
        properties => [qw/ url /],
        desc => sprintf('Found existing assembly with url: %s', join(',', map { $_->__display_name__} @existing_assemblies)),
    ) if @existing_assemblies;

    @errors;
}

sub mkoutput_types { (qw/ raw megabubbles psuedohap2 /) }

1;
