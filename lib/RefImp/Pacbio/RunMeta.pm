package RefImp::Pacbio::RunMeta;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/ metadata_xml_file sample_name well analysis_files /);

sub new {
    my ($class, %params) = @_;
    bless \%params, $class;
}

1;
