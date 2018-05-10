package RefImp::Pacbio::RunMeta;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/ metadata_xml_file sample_name well analysis_files /);

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

1;
