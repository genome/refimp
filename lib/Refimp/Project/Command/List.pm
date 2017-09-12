package Refimp::Project::Command::List;

use strict;
use warnings;

class Refimp::Project::Command::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'Refimp::Project',
        },
        show => { default_value => 'id,name,status', },
    },
    doc => 'list projects and properties',
};

1;

