package Pacbio::Run;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/ _analyses directory machine_type /);

use List::MoreUtils;

use Pacbio::Run::AnalysisFactoryForRsii;
use Pacbio::Run::AnalysisFactoryForSequel;

sub valid_machine_types { (qw/ rsii sequel /) }

sub __name__ { join(' ', map { $_[0]->$_ } (qw/ directory machine_type /)) }

sub new {
    my ($class, %params) = @_;

    my $self = bless \%params, $class;

    die "No directory given!" if not $self->directory;
    die "Directory given does not exist: ".$self->directory if not -d $self->directory->stringify;
    die "No machine_type given!" if not $self->machine_type;
    die "Invalid machine_type given: ".$self->machine_type if not List::MoreUtils::any { $self->machine_type eq $_ } $self->valid_machine_types;

    $self;
}

sub analyses_for_sample {
    my ($self, $sample_name_regex) = @_;
    die "No sample name regex given!" if not $sample_name_regex;

    my $analyses = $self->analyses;
    my @sample_analyses;
    for my $analysis ( @$analyses ) {
        push @sample_analyses, $analysis if $analysis->library_name =~ $sample_name_regex;
    }

    return if not @sample_analyses;
    \@sample_analyses;
}

sub analyses_count {
    my ($self) = @_;
    my $analyses = $self->analyses;
    ( $analyses ? scalar(@$analyses) : 0 );
}

sub analyses {
    my ($self) = @_;
    return $self->_analyses if $self->_analyses;
    my $analyses;
    if ( $self->machine_type eq 'rsii' ) {
        $analyses = Pacbio::Run::AnalysisFactoryForRsii->build($self->directory)
    }
    else {
        $analyses = Pacbio::Run::AnalysisFactoryForSequel->build($self->directory)
    }
    return if not $analyses;
    $self->_analyses($analyses);
}

1;
