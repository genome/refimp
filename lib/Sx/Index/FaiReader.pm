package Sx::Index::FaiReader;

use strict;
use warnings 'FATAL';

use IO::File;

sub io { $_[0]->{io} }

sub new {
    my ($class, $file) = @_;

    die "No index file given!" if not $file;
    die "Index file does not exist! $file" if not -s $file;
    my $io = IO::File->new($file, 'r');
    die "Failed to open file: $file" if not $io;

    my %self = ( io => $io );
    bless(\%self, $class);
}

sub read {
    my ($self) = @_;

    my $line = $self->io->getline;
    return if not $line;

    #000000F_001|arrow   368138  19  60  61
    chomp $line;
    my (@tokens) = split(/\t/, $line);
    my %entry;
    @entry{qw/ id length offset linebases linewidth /} = @tokens; #also: qualoffset
    \%entry;
}

sub reset { $_[0]->io->seek(0, 0) }
sub tell { $_[0]->io->tell }
sub seek {
    die "No position to seek!" if not defined $_[1];
    $_[0]->io->seek($_[1], 0);
}

1;
