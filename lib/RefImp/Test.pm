package RefImp::Test;

use strict;
use warnings;

use File::Spec;
use File::Basename 'dirname';
use Params::Validate ':types';

sub test_data_directory {
    my @directory_parts = File::Spec->splitdir( File::Spec->rel2abs( dirname(__FILE__) ) );
    splice @directory_parts, -2, 2;
    return File::Spec->join(@directory_parts, 't.d');
}

sub test_data_directory_for_package {
    my ($class, $pkg) = Params::Validate::validate_pos(@_, {isa => __PACKAGE__}, {type =>SCALAR});
    return File::Spec->join($class->test_data_directory, join('-', split('::', $pkg)));
}

sub set_seqmgr_test_data_directory {
    my $class = shift;
    return RefImp::Config::set('seqmgr', File::Spec->join($class->test_data_directory, 'seqmgr'));
}

sub set_analysis_directory_test_data_directory {
    my $class = shift;
    return RefImp::Config::set('analysis_directory', File::Spec->join($class->test_data_directory, 'analysis'));
}

1;

