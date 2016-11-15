package RefImp::Project::Submissions;

use strict;
use warnings 'FATAL';

use File::Path 'make_path';
use File::Spec;
use Params::Validate qw/ :types validate_pos /;
use RefImp::Config;

sub analysis_directory_for_taxon {
    my ($class, $taxon) = validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Taxon'});
    return File::Spec->join( RefImp::Config::get('analysis_directory'), $taxon->species_short_name );
}

sub analysis_directory_for_clone {
    my ($class, $clone) = validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Clone'});
    my $taxon = RefImp::Taxon->get_for_clone($clone);
    die "No taxon for clone! ".$clone->__display_name__ if not $taxon;
    return File::Spec->join( $class->analysis_directory_for_taxon($taxon), lc($clone->name) );
}

sub new_analysis_subdirectory_for_clone {
    my ($class, $clone) = validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Clone'});

    my @time = localtime;
    my $analysis_subdirectory = File::Spec->join(
        $class->analysis_directory_for_clone($clone),
        sprintf('%02s%02s%02s', $time[5] + 1900, $time[4] + 1, $time[3]),
    );
    if ( not -d $analysis_subdirectory ) {
        make_path($analysis_subdirectory)
            or die 'Failed to make new analysis subdirectory for clone: '.$clone->name;
    }

    return $analysis_subdirectory
}

sub submit_form_file_name_for_clone {
    my ($class, $clone) = validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Clone'});
    join('.', $clone->name, 'submit', 'form');
}

sub submit_info_yml_file_name_for_clone {
    my ($class, $clone) = validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Clone'});
    join('.', $clone->name, 'submit', 'yml');
}

sub raw_sqn_template_for_taxon {
    my ($class, $taxon) = validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Taxon'});
    my $raw_template_path = File::Spec->join(
        RefImp::Config::get('analysis_directory'),
        'templates',
        join('_', 'raw', $taxon->species_short_name, 'template'),
    );
    $raw_template_path .= '.sqn';
    return $raw_template_path;
}

1;

