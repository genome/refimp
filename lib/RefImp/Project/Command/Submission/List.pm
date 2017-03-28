package RefImp::Project::Command::Submission::List;

use strict;
use warnings;

class RefImp::Project::Command::Submission::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'RefImp::Project::Submission',
        },
        show => { default_value => 'project.name,project_size,submitted_on,directory', },
    },
    doc => 'list projects and properties',
};

1;

