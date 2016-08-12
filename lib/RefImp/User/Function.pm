package RefImp::User::Function;

use strict;
use warnings;

use RefImp;

=doc 2016-06

USER_FUNCTION	GSC::UserFunction	oltp	production

    CREATION_EVENT_ID creation_event_id NUMBER(10)    (fk)
  x EI_ID             ei_id             NUMBER(10)    (pk)
  x FUNCTION_ID       function_id       NUMBER(10)    (fk)
  x GU_ID             gu_id             NUMBER(10)    (fk)
  x STATUS            status            VARCHAR2(16)  (fk)

=cut

class RefImp::User::Function {
    table_name => 'user_function',
    id_by => {
        id => { is => 'Integer', column_name => 'ei_id', },
    },
    has => {
        function_id => { is => 'Integer', },
        gu_id => { is => 'Integer', },
        user => { is => 'RefImp::User', id_by => 'gu_id', },
        status => { is => 'String', },
        work_function => {
            is => 'RefImp::User::WorkFunction',
            id_by => 'id',
        },
        name => {
            is => 'String',
            via => 'work_function',
            to => 'name',
        },
    },
    has_calculated => {
        is_active => {
            calculate_from => [qw/ status /],
            calculate => q/ $status eq 'active' /,
        },
    },
    data_source => RefImp::Config::get('ds_oltp'),
};

1;

