package Tenx::Reference::Command;

use strict;
use warnings 'FATAL';

use UR::Object::Command::Crud;
UR::Object::Command::Crud->create_command_subclasses(
    target_class => 'Tenx::Reference',
    target_name => 'reference',
    sub_command_configs => {
        copy => { skip => 1, },
    },
);

1;
