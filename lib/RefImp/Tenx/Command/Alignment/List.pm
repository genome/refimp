package RefImp::Tenx::Command::Alignment::List;

use strict;
use warnings;

class RefImp::Tenx::Command::Alignment::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'RefImp::Tenx::Alignment',
        },
        show => { default_value => 'id,reads.sample_name,reference.name,directory', },
    },
    doc => 'list tenx reads and properties',
};

1;
