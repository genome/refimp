package RefImp::Pacbio::Run;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/ directory machine_type /);

use List::MoreUtils;

use RefImp::Pacbio::Run::AnalysisFactoryForRsii;
use RefImp::Pacbio::Run::AnalysisFactoryForSequel;

sub valid_machine_types { (qw/ rsii sequel /) }

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
        push @sample_analyses, $analysis if $analysis->sample_name =~ $sample_name_regex;
    }

    return if not @sample_analyses;
    \@sample_analyses;
}

sub analyses {
    my ($self) = @_;
    if ( $self->machine_type eq 'rsii' ) {
        RefImp::Pacbio::Run::AnalysisFactoryForRsii->build($self->directory)
    }
    else {
        RefImp::Pacbio::Run::AnalysisFactoryForSequel->build($self->directory)
    }
}

1;
