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
        show => { default_value => 'id,sample_name,directory,targets_path', },
    },
    doc => 'list tenx reads and properties',
};

1;
