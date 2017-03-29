package RefImp::Project::Submissions;

use strict;
use warnings 'FATAL';

use File::Path 'make_path';
use File::Spec;
use Params::Validate qw/ :types validate_pos /;
use RefImp::Config;

sub submit_form_file_name_for_project {
    my ($class, $project) = validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Project'});
    join('.', $project->name, 'submit', 'form');
}

sub submit_info_yml_file_name_for_project {
    my ($class, $project) = validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Project'});
    join('.', $project->name, 'submit', 'yml');
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

