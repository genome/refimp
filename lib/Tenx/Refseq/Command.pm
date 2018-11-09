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

use Sub::Install;
Sub::Install::reinstall_sub({
        code => sub{ 'tech=tenx' },
        into => 'Tenx::Refseq::Command::List',
        as => '_base_filter',
    });

my $meta = UR::Object::Type->get('Tenx::Refseq::Command::Create');
$meta->property_meta_for_name('tech')->default_value('tenx');

1;
