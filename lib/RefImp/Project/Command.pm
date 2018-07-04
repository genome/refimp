package RefImp::Project::Command;

use strict;
use warnings 'FATAL';

use UR::Object::Command::Crud;

UR::Object::Command::Crud->create_command_subclasses(
    target_class => 'RefImp::Project',
    target_name => 'project',
    namespace => 'RefImp::Project::Command',
    sub_command_configs => {
        copy => { skip => 1, },
		update => { exclude => [qw/ mystatus name status /], },
    },
);

1;
