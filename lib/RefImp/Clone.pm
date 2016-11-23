package RefImp::Clone;

use strict;
use warnings;

use RefImp::Project::NotesFile;
use RefImp::Taxon;

use File::Spec;
use Params::Validate qw( :types validate_pos );
use RefImp::Resources::LimsRestApi;

=doc 2016-03-15

CLONES	GSC::Clone	oltp	production

     CHR_CHROMOSOME      chromosome          VARCHAR2(8)           (fk)    
   x CLO_ID              clo_id              NUMBER(15)            (pk)(fk)
     CLONE_DATE_RECEIVED clone_date_received DATE(19)                      
     CLONE_EXTENSION     clone_extension     VARCHAR2(4)  NULLABLE         
   x CLONE_NAME          clone_name          VARCHAR2(64)          (unique)
     CLOPRE_CLONE_PREFIX clone_prefix        VARCHAR2(16)                  
     CLONE_SIZE          clone_size          VARCHAR2(16)                  
   x CS_CLONE_STATUS     clone_status        VARCHAR2(64)          (fk)    
   x CT_CLONE_TYPE       clone_type          VARCHAR2(25)          (fk)    
     GAP                 gap                 VARCHAR2(2)  NULLABLE         
     MAP_LOCATION        map_location        VARCHAR2(64) NULLABLE         
     MAP_ORDER           map_order           VARCHAR2(64)                  

=cut

class RefImp::Clone {
    table_name => 'clones',
    id_by => {
        id => { is => 'Integer', column_name => 'clo_id', },
    },
    has => {
        name => { is => 'Text', column_name => 'clone_name', doc => 'Name of the clone.', },
        status => { is => 'Text', column_name => 'cs_clone_status', doc => 'Status of the clone.', },
        type => { is => 'Text', column_name => 'ct_clone_type', doc => 'Clone type: bac, cosmid, etc.', },
    },
    has_calculated_constant => {
        project => {
            calculate_from => [qw/ name /],
            calculate => q{ RefImp::Project->get(name => $name) },
        },
    },
    data_source => RefImp::Config::get('ds_oltp'),
};

sub __display_name__ { sprintf('%s (%s)', $_[0]->name, $_[0]->id) }

1;

