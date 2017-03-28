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

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->submitted_on( UR::Context->now );

    return $self;
}

1;
