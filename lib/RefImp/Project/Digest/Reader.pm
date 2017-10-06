package RefImp::Project::Digest::Reader;

use strict;
use warnings 'FATAL';

use Params::Validate qw/ :types validate_pos /;
use RefImp::Project::Digest;

sub new {
    my ($class, %params) = @_;

    my $self = bless \%params, $class;

    if ( not exists $self->{file} ) {
        die "No sizes file given to reader!";
    }

    if ( not -s $self->{file} ) {
        die "Invalid sizes file ($self->{file}) given to reader!";
    }

    $self->{fh} = IO::File->new($self->{file}, 'r');
    if ( not $self->{fh} ) {
        die "Failed to open $self->{file}: $!";
    }

    return $self;
}

sub next_for_project {
    my ($self, $project_name) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    my $digest = RefImp::Project::Digest->new($project_name);
    while ( my %info = $self->_next) {
        last if $digest->add_digest_info(%info);
    }

    return if not $digest->bands;
    $digest;
}

sub _next {
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
    my @bands;
    for ( my $i = 0; $i <= $digest{band_cnt}; $i++ ) {
        my $line = $self->{fh}->getline;
        chomp $line;
        push @bands, $line;
    }
    die "ERROR Read incorrect number of bands!" if $bands[ $#bands ] ne '-1';
    $digest{bands} = \@bands;

    %digest;
}

1;

