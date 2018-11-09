package Tenx::Reads::Command;

use strict;
use warnings 'FATAL';

use UR::Object::Command::Crud;
UR::Object::Command::Crud->create_command_subclasses(
    namespace => 'Tenx::Reads::Command',
    target_class => 'RefImp::Reads',
    target_name => 'reads',
    sub_command_configs => {
        copy => { skip => 1, },
    },
);

1;
