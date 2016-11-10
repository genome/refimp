package RefImp::Project::Prefinisher;

use strict;
use warnings;

=pod

PROJECT_PREFINISHERS	GSC::ProjectPrefinisher	oltp	production

  x EI_EI_ID           ei_id      NUMBER(10)  (pk)(fk)
  x PROJECT_PROJECT_ID project_id NUMBER(10)  (pk)(fk)

=cut

class RefImp::Project::Prefinisher { 
    is => 'RefImp::Project::Claimer', 
    table_name => 'project_prefinishers',
    data_source => RefImp::Config::get('ds_oltp'),
    id_by => {
        project_id => { is => 'Integer', column_name => 'project_project_id', },
        ei_id => { is => 'Integer', column_name => 'ei_ei_id', },
    },
};

sub claimer_type { 'prefinisher' }

1;

