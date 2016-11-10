package RefImp::Project::StatusHistory;

use strict;
use warnings;

=pod

PROJECT_STATUS_HISTORIES	GSC::ProjectStatusHistory	oltp	production

    PROJECT_PROJECT_ID project_id     NUMBER(10)    (pk)(fk)
    PS_PROJECT_STATUS  project_status VARCHAR2(22)  (pk)(fk)
    STATUS_DATE        status_date    DATE(19)      (pk)    

=cut

class RefImp::Project::StatusHistory { 
    table_name => 'project_status_histories',
    id_by => {
        project_id => { is => 'Integer', column_name => 'project_project_id', },
        project_status => { is => 'Text', column_name => 'ps_project_status', },
        status_date => { is => 'Date', },
    },
    has => {
        project => {
            is => 'RefImp::Project',
            id_by => 'project_id',
            doc => 'The project.',
        },
    },
    data_source => RefImp::Config::get('ds_oltp'),
};

sub create {
    my ($class, %params) = @_;

    $params{status_date} = UR::Context->now;
    my $self = $class->SUPER::create(%params);
    return if not $self;

    if ( not $self->project ){
        $self->fatal_message('Failed to find project for id! %s', $self->project_id);
    }
    $self->project->__status( $self->project_status );

    return $self;
}

1;

