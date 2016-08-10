package RefImp::Clone::Command::List;

use strict;
use warnings;

use RefImp;

class RefImp::Clone::Command::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'RefImp::Clone',
        },
        show => { default_value => 'id,name,status,type', },
    },
    doc => 'list clones and properties',
};

1;

