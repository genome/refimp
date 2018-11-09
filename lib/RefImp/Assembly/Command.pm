package RefImp::Assembly::Command;

use strict;
use warnings;

use UR::Object::Command::Crud;
UR::Object::Command::Crud->create_command_subclasses(
    target_class => 'RefImp::Assembly',
    target_name => 'assmbly',
    namespace => 'RefImp::Assembly::Command',
    sub_command_configs => {
        copy => { skip => 1, },
        list => { show => 'id,name,taxon,tech,url', },
        update => { skip => 1, },
        delete => { skip => 1, },
    },
);

1;
