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
    },
);

sub get_assembly {
    my ($class, $key) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    if ( $key =~ /^[\w\d]{32}$/ ) { # id
        return RefImp::Assembly->get($key);
    }

    my $assembly = RefImp::Assembly->get(url => $key); # get by url
    return $assembly if $assembly;

    RefImp::Assembly->__define__(
        name => dir($key)->basename,
        url => $key,
    ); # define by url

}

1;
