package RefImp::Assembly::Command::Submissions;

use strict;
use warnings;

class RefImp::Assembly::Command::Submissions {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'RefImp::Assembly::Submission',
        },
        #show => { default_value => '', },
    },
    doc => 'list assembly submissions',
};

1;
