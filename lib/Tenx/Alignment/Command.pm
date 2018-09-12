package Tenx::Alignment::Command;

use strict;
use warnings 'FATAL';

use UR::Object::Command::Crud;
UR::Object::Command::Crud->create_command_subclasses(
    target_class => 'Tenx::Alignment',
    target_name => 'alignment',
    namespace => 'Tenx::Alignment::Command',
    sub_command_configs => {
        copy => { skip => 1, },
    },
);

1;
