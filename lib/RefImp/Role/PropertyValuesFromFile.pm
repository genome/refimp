package RefImp::Role::PropertyValuesFromFile;

use strict;
use warnings;

use File::Slurp;

sub class_properties_can_load_from_file {
    my $class = shift;

    $class->fatal_message("Failed to add role to %s. It is not a 'Command::V2'.", $class) if not $class->isa('Command::V2');
    my $orig_sub = $class->can('_params_to_resolve');
    $class->fatal_message("Failed to add role to %s. Cannot find '_params_to_resolve'.", $class) if not $orig_sub;
    Sub::Install::reinstall_sub({
        code => sub{
            my ($class, $params) = @_;
            _load_property_values_from_file($class, $params);
            $orig_sub->($class, $params);
        },
        into => $class,
        as => '_params_to_resolve',
    });

    for my $property_name ( @_ ) {
        my $property = $class->__meta__->property_meta_for_name($property_name);
        $class->fatal_message('Failed to add role to %s. No property meta for %s', $class, $property_name) if not $property;
        $class->fatal_message("Failed to add role to %s. Property, %s, is not is_many.", $class, $property_name) if not $property->is_many;
        $property->{can_load_from_file} = 1;
        $property->{doc} .= ' Optionally, pass a single columned file to load values.';
    }
}

sub _load_property_values_from_file {
    my ($class, $params) = @_;

    for my $property ( $class->__meta__->property_metas ) {
        next if not $property->{can_load_from_file};
        my $property_name = $property->property_name;
        my $values = $params->{$property_name};
        next if not $values or not @$values or @$values > 1 or ! -s $values->[0];
        $values = [ map { chomp; $_ } File::Slurp::read_file($values->[0]) ];
        $params->{$property_name} = $values;
    }
}

1;
