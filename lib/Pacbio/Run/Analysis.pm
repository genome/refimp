package Pacbio::Run::Analysis;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/ metadata_xml_file library_name plate_id version well analysis_files /);

sub __name__ { join(' ', map { $_[0]->$_ } (qw/ plate_id well library_name /)); }

sub new {
    my ($class, %params) = @_;
    $params{analysis_files} = [] if not $params{analysis_files};
    bless \%params, $class;
}

sub add_analysis_files {
    my ($self, @files) = @_;
    die "No analysis file given!" if not @files;
    my $analysis_files = $self->analysis_files;
    push @$analysis_files, @files;
    $self->analysis_files;
}

sub alias { # PLATE_WELL was: 6U00E3_1020_A01_1
	my $self = shift;
    my $alias = join('_', $self->plate_id, $self->well);
    $alias =~ s/ /_/g;
	$alias;
}

1;
