package RefImp::Pacbio::RunMeta;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/ metadata_xml_file sample_name plate_id version well analysis_files /);

#library_name      => $name,
#bioproject        => $params{bioproject_id},
#biosample         => $params{biosample_id},
#instrument        => 'PacBio RS II',
#library_strategy  => 'WGS',
#library_source    => 'GENOMIC',
#library_selection => 'unspecified',
#library_layout    => 'single',
#run_data          => [], # data_blocks below

sub new {
    my ($class, %params) = @_;
    $params{analysis_files} = [] if not $params{analysis_files};
    bless \%params, $class;
}

sub add_analysis_file {
    my ($self, $file) = @_;
    die "No analysis file given!" if not $file;
    my $analysis_files = $self->analysis_files;
    push @$analysis_files, $file;
    $self->analysis_files;
}

sub alias { # PLATE_WELL was: 6U00E3_1020_A01_1
	my $self = shift;
    my $alias = join('_', $self->plate_id, $self->well);
    $alias =~ s/ /_/g;
	$alias;
}

1;
