package Sx::Index::Fai;

use strict;
use warnings 'FATAL';

use Sx::Index::FaiReader;

sub ids_and_positions { $_[0]->{ids_and_positions} }
sub reader { $_[0]->{reader} }

sub new {
    my ($class, $file) = @_;

    my $position = 0;
    my %ids_and_positions;
    my $reader = Sx::Index::FaiReader->new($file);
    while ( my $e = $reader->read ) {
        $ids_and_positions{ $e->{id} } = $position;
        $position = $reader->tell;
    }

    my %self = (
        reader => $reader,
        ids_and_positions => \%ids_and_positions,
    );

    bless(\%self, $class);
}

sub entry_for_id {
    my ($self, $id) = @_;
    die "No id given to get entry!" if not defined $id;
    return if not exists $self->ids_and_positions->{$id};
    $self->reader->seek($self->ids_and_positions->{$id});
    $self->reader->read;
}

sub entries_for_id_regex {
    my ($self, $id) = @_;
    die "No id regex given to get entries!" if not defined $id;

    my $regex = qr/$id/;
    my $ids_and_positions = $self->ids_and_positions;
    my @ids = grep { $_ =~ /$regex/ } keys %$ids_and_positions;
    return if not @ids;

    my @e;
    my $reader = $self->reader;
    for my $id ( @ids ) {
        $reader->seek($ids_and_positions->{$id});
        push @e, $reader->read;
    }

    [ sort { $a->{offset} <=> $b->{offset} } @e ];
}

1;
