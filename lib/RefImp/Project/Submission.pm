package RefImp::Project::Submission;

use strict;
use warnings;

class RefImp::Project::Submission {
    table_name => 'projects_submissions',
    #id_generator => '-uuid',
    #id_by => {
    #    id => { is => 'Text', },
    #},
    id_by => {
        project_id => { is => 'Text', },
        submitted_on => { is => 'DateTime', },
    },
    has => {
        accession_id => { is => 'Text', },
        project => { is => 'RefImp::Project', id_by => 'project_id', },
    },
    has_optional => {
        directory => { is => 'Text', },
        phase => { is => 'Text', },
        project_size => { is => 'Number', },
    },
    data_source => RefImp::Config::get('ds_mysql'),
};

sub __display_name__ {
    return sprintf('%s on %s (%s)', $_[0]->project->name, $_[0]->date, $_[0]->directory || 'NA');
}

sub create {
    my ($class, %params) = @_;

    $params{submitted_on} = UR::Context->now;
    $class->SUPER::create(%params);
}

1;
