package Tenx::Refseq::Command;

use strict;
use warnings 'FATAL';

use UR::Object::Command::Crud;
UR::Object::Command::Crud->create_command_subclasses(
    namespace => 'Tenx::Refseq::Command',
    target_class => 'RefImp::Refseq',
    target_name => 'refseq',
    sub_command_configs => {
        copy => { skip => 1, },
    },
);

1;
