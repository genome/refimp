package Refimp::Assembly::Command::Submission::List;

use strict;
use warnings;

class Refimp::Assembly::Command::Submission::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'Refimp::Assembly::Submission',
        },
        show => { default_value => 'id,bioproject,biosample,submitted_on,directory', },
    },
    doc => 'list assembly submissions',
};

1;
