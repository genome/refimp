package Tenx::Assembly::Command;

use strict;
use warnings 'FATAL';

use UR::Object::Command::Crud;
UR::Object::Command::Crud->create_command_subclasses(
    target_class => 'Tenx::Assembly',
    target_name => 'assembly',
    namespace => 'Tenx::Assembly::Command',
    sub_command_configs => {
        copy => { skip => 1, },
    },
);

1;
