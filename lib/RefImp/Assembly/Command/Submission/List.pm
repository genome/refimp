package RefImp::Assembly::Command::Submission::List;

use strict;
use warnings;

class RefImp::Assembly::Command::Submission::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'RefImp::Assembly::Submission',
        },
        show => { default_value => 'id,bioproject,biosample,submitted_on,directory', },
    },
    doc => 'list assembly submissions',
};

1;
