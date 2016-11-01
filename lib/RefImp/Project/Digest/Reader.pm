package RefImp::Project::Digest::Reader;

use strict;
use warnings 'FATAL';

sub new {
    my ($class, %params) = @_;

    my $self = bless \%params, $class;
    if ( not $self->{file} and not -s $self->{file} ) {
        die "ERROR No sizes file given to reader!";
    }

    $self->{fh} = IO::File->new($self->{file}, 'r');
    if ( not $self->{fh} ) {
        die "ERROR Failed to open $self->{file}: $!";
    }

    return $self;
}

sub next {
    my $self = shift;

    my $digest = $self->_next_digest_header;
    return if not $digest;

    my @bands;
    for ( my $i = 0; $i <= $digest->{band_cnt}; $i++ ) {
        my $line = $self->{fh}->getline;
        chomp $line;
        push @bands, $line;
    }

    die "ERROR Read incorrect number of bands!" if $bands[ $#bands ] ne '-1';
    $digest->{bands} = \@bands;

    return $digest;
}

sub _next_digest_header {
    my $self = shift;

    my $header_line;
    while ( my $line = $self->{fh}->getline ) {
        chomp $line;
        $line =~ s/^\s+//g;
        next if $line =~ /^$/;
        next if $line =~ /^\d+$/;
        next if $line eq '-1';
        $header_line = $line;
        last;
    }

    return if not $header_line;

    my %digest;
    @digest{qw/ project_header band_cnt date /} = split(/\s+/, $header_line);
    \%digest;
}

1;

