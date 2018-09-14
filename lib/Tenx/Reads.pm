package Tenx::Reads;

use strict;
use warnings;

use Path::Class;

class Tenx::Reads {
    table_name => 'tenx_reads',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        directory => { is => 'Text', doc => 'File system location of the read files', },
        sample_name => { is => 'Text', doc => 'Teh unique sample name.', },
    },
    has_optional => {
        targets_path => { is => 'Text', doc => 'The targets file, if exome.', },
    },
    has_optional_calculated => {
        type => {
            calculate_from => [qw/ targets_path /],
            calculate => q| ( defined $targets_path ? 'targeted' : 'wgs' ) |,
        },
    },
    data_source => Tenx::Config::get('tenx_ds'),
};

sub __display_name__ { sprintf('%s (%s %s)', $_[0]->sample_name, $_[0]->type, $_[0]->directory) }


sub __errors__ {
    my $self = shift;

    my @errors = $self->SUPER::__errors__;
    return @errors if @errors;

    push @errors, UR::Object::Tag->create(
        type => 'error',
        properties => [qw/ directory /],
        desc => 'Reads directory does not exist: '.$self->directory,
    ) if !-d $self->directory;


    my @existing_reads = grep { $_->id ne $self->id } __PACKAGE__->get(directory => $self->directory);
    push @errors, UR::Object::Tag->create(
        type => 'error',
        properties => [qw/ directory /],
        desc => sprintf('Found existing reads with directory: %s', join(',', map { $_->__display_name__} @existing_reads)),
    ) if @existing_reads;

    push @errors, UR::Object::Tag->create(
        type => 'error',
        properties => [qw/ targets_path /],
        desc => 'Targets path does not exist: '.$self->targets_path,
    ) if $self->targets_path and !-s $self->targets_path;

    @errors;
}

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->directory( dir($self->directory)->absolute->stringify );
    $self->targets_path( dir($self->targets_path)->absolute->stringify ) if $self->targets_path;

    my @errors = $self->__errors__;
    $self->fatal_message( join("\n", map { $_->__display_name__ } @errors) ) if @errors;

    $self;
}

1;
