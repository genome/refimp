package Tenx::Assembly::Command;

use strict;
use warnings 'FATAL';

use Path::Class 'dir';
use Params::Validate qw/ :types validate_pos /;

use UR::Object::Command::Crud;
UR::Object::Command::Crud->create_command_subclasses(
    target_class => 'RefImp::Assembly',
    target_name => 'assembly',
    namespace => 'Tenx::Assembly::Command',
    sub_command_configs => {
        copy => { skip => 1, },
        list => { show => 'id,name,taxon,url', },
    },
);

use Sub::Install;
Sub::Install::reinstall_sub({
        code => sub{ 'tech=tenx' },
        into => 'Tenx::Assembly::Command::List',
        as => '_base_filter',
    });

my $meta = UR::Object::Type->get('Tenx::Assembly::Command::Create');
$meta->property_meta_for_name('tech')->default_value('tenx');

sub get_assembly {
    my ($class, $key) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    if ( $key =~ /^[\w\d]{32}$/ ) { # id
        return RefImp::Assembly->get($key);
    }

    my $assembly = RefImp::Assembly->get(url => $key); # get by url
    return $assembly if $assembly;

    RefImp::Assembly->__define__(
        name => dir($key)->basename,
        tech => 'tenx',
        url => $key,
    ); # define by url

}

1;
