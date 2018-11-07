package Tenx::Assembly;

use strict;
use warnings 'FATAL';

class Tenx::Assembly {
    table_name => 'tenx_assemblies',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        url => { is => 'Text', doc => 'Assembly location: file system, cloud.', },
        reads => {
            is => 'RefImp::Reads',
            id_by => 'reads_id',
            doc => 'The reads that are assembled.',
        },
    },
    has_optional => {
        sample_name => { is => 'Text', is_transient => 1, }, # FIXME
        status => {
            is => 'Text',
            doc => 'The status of the assembly: running, succeeded, failed, etc.',
        },
    },
    data_source => Tenx::Config::get('tenx_ds'),
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
