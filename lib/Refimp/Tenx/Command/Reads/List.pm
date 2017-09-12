package Refimp::Tenx::Command::Reads::List;

use strict;
use warnings;

class Refimp::Tenx::Command::Reads::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'Refimp::Tenx::Reads',
        },
        show => { default_value => 'id,sample_name,directory,targets_path', },
    },
    doc => 'list tenx reads and properties',
};

1;
