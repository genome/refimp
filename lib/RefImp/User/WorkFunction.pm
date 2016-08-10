package RefImp::User::WorkFunction;

use strict;
use warnings;

use RefImp;

=doc 2016-06

WORK_FUNCTION	GSC::WorkFunction	oltp	production

    CREATION_EVENT_ID creation_event_id NUMBER(10)             (fk)    
    DESCRIPTION       description       VARCHAR2(256) NULLABLE         
 x  FUNCTION_ID       function_id       NUMBER(10)             (pk)    
 x  NAME              name              VARCHAR2(100)          (unique)
    PERMISSION        permission        VARCHAR2(16)                   
 x  STATUS            status            VARCHAR2(8)                    
    TYPE              type              VARCHAR2(32)  NULLABLE         

=cut

class RefImp::User::WorkFunction {
    table_name => 'work_function',
    id_by => {
        id => { is => 'Integer', column_name => 'function_id', },
    },
    has => {
        name => { is => 'String', },
        status => { is => 'String', },
    },
    data_source => 'RefImp::DataSource::Oltp',
};

1;

