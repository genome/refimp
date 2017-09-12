package Refimp::Assembly::Command::List;

use strict;
use warnings;

class Refimp::Assembly::Command::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'Refimp::Assembly',
        },
        show => { default_value => 'id,name,taxon,directory', },
    },
    doc => 'list assemblies and properties',
};

1;
