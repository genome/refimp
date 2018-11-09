package Tenx::Alignment::Command;

use strict;
use warnings 'FATAL';

use UR::Object::Command::Crud;
UR::Object::Command::Crud->create_command_subclasses(
    target_class => 'RefImp::Alignment',
    target_name => 'alignment',
    namespace => 'Tenx::Alignment::Command',
    sub_command_configs => {
        copy => { skip => 1, },
    },
);

use Sub::Install;
Sub::Install::reinstall_sub({
        code => sub{ 'tech=tenx' },
        into => 'Tenx::Alignment::Command::List',
        as => '_base_filter',
    });

my $meta = UR::Object::Type->get('Tenx::Alignment::Command::Create');
$meta->property_meta_for_name('tech')->default_value('tenx');

1;
