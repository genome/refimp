package RefImp::Taxon::Command::List;

use strict;
use warnings;

class RefImp::Taxon::Command::List {
    is => 'UR::Object::Command::List',
    has => {
        subject_class_name  => {
            is_constant => 1,
            value => 'RefImp::Taxon',
        },
        show => { default_value => 'id,name,species_name', },
    },
    doc => 'list taxa and properties',
};

1;
