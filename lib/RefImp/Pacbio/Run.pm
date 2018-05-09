package RefImp::Pacbio::Run;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
RefImp::Pacbio::Run->mk_accessors(qw/ directory /);

use Data::Dumper 'Dumper';
use RefImp::Pacbio::RunMetadata;

sub new {
    my ($class, $directory) = @_;

    my %self = (
        directory => $directory,
    );

    bless \%self, $class;
}

sub analysis_files_for_sample {
    my ($self, $sample) = @_;
}

1;
