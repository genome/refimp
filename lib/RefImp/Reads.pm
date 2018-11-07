package RefImp::Reads;

use strict;
use warnings 'FATAL';

use Path::Class;

class RefImp::Reads {
    table_name => 'reads',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        url => { is => 'Text', doc => 'File system location of the read files', },
        sample_name => { is => 'Text', doc => 'Teh unique sample name.', },
    },
    has_optional => {
        targets_url => { is => 'Text', doc => 'The targets file, if exome.', },
    },
    has_optional_calculated => {
        type => {
            calculate_from => [qw/ targets_url /],
            calculate => q| ( defined $targets_url ? 'targeted' : 'wgs' ) |,
        },
    },
    data_source => RefImp::Config::get('refimp_ds'),
};

sub __display_name__ { sprintf('%s (%s %s)', $_[0]->sample_name, $_[0]->type, $_[0]->url) }

sub __errors__ {
    my $self = shift;

    my @errors = $self->SUPER::__errors__;
    return @errors if @errors;

    my @existing_reads = grep { $_->id ne $self->id } __PACKAGE__->get(url => $self->url);
    push @errors, UR::Object::Tag->create(
        type => 'error',
        properties => [qw/ url /],
        desc => sprintf('Found existing reads with url %s', join(',', map { $_->__display_name__} @existing_reads)),
    ) if @existing_reads;

    push @errors, UR::Object::Tag->create(
        type => 'error',
        properties => [qw/ targets_url /],
        desc => 'Targets url does not exist: '.$self->targets_url,
    ) if $self->targets_url and !-s $self->targets_url;

    @errors;
}

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->url( dir($self->url)->absolute->stringify );
    $self->targets_url( dir($self->targets_url)->absolute->stringify ) if $self->targets_url;

    my @errors = $self->__errors__;
    $self->fatal_message( join("\n", map { $_->__display_name__ } @errors) ) if @errors;

    $self;
}

1;
