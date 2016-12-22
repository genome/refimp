package RefImp::Role::PropertyValuesFromFile;

use strict;
use warnings;

use File::Slurp;

sub class_properties_can_load_from_file {
    my $class = shift;

    UR::Observer->register_callback(
        subject_class_name => $class,
        aspect => 'create',
        callback => \&_load_property_values_from_file,
    );

    for my $property_name ( @_ ) {
        my $property = $class->__meta__->property_meta_for_name($property_name);
        $class->fatal_message('No property for %s to allow loading values from a file!', $property_name) if not $property;
        $property->{can_load_from_file} = 1;
        $property->{doc} .= ' Optionally, pass a file to load values.';
    }
}

sub _load_property_values_from_file {
    my $self = shift;

    for my $property ( $self->__meta__->property_metas ) {
        next if not $property->{can_load_from_file};
        my $property_name = $property->property_name;
        my @values = $self->$property_name;
        next if not @values or @values > 1 or ! -s $values[0];
        $self->$property_name([ map { chomp; $_ } File::Slurp::read_file($values[0]) ]);
    }

}

1;

