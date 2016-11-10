package RefImp::Project::Command::List;

use strict;
use warnings;

class RefImp::Project::Command::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'RefImp::Project',
        },
        show => { default_value => 'id,name,status', },
    },
    doc => 'list projects and properties',
};

1;

