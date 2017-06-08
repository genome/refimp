package RefImp::Tenx::Command::Reference::List;

use strict;
use warnings;

class RefImp::Tenx::Command::Reference::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'RefImp::Tenx::Reference',
        },
        show => { default_value => 'id,name,directory', },
    },
    doc => 'list tenx references and properties',
};

1;

