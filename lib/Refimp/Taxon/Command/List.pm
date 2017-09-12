package Refimp::Taxon::Command::List;

use strict;
use warnings;

class Refimp::Taxon::Command::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'Refimp::Taxon',
        },
        show => { default_value => 'id,name,species_name', },
    },
    doc => 'list taxa and properties',
};

1;
