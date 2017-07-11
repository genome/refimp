package RefImp::Tenx::Command::Reads::Create;

use strict;
use warnings;

use Path::Class;

use RefImp::Tenx::Reads;
my %inputs = map {
        $_->property_name => {
            is => $_->data_type,
            is_optional => $_->is_optional,
            doc => $_->doc,
        }
    } grep {
        $_->property_name !~ /id$/
} RefImp::Tenx::Reads->__meta__->properties;

class RefImp::Tenx::Command::Reads::Create { 
    is => 'Command::V2',
    has_input => \%inputs,
    doc => 'create a longranger reads db entry',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 
    $self->status_message('Create longranger reads...');

    my %params = map { $_ => $self->$_ } keys %inputs;
    $self->status_message("Params:\n%s", YAML::Dump( {map { $_ => ( ref $params{$_} ? $params{$_}->id : $params{$_} ) } keys %params }));
    my $reads = RefImp::Tenx::Reads->create(%params);
    $self->status_message('Created reads: %s', $reads->__display_name__);

    1;
}

1;
