package RefImp::Tenx::Command::Reference::Create;

use strict;
use warnings;

use Path::Class;

use RefImp::Tenx::Reference;
my %inputs = map {
        $_->property_name => {
            is => $_->data_type,
            doc => $_->doc,
        }
    } grep {
        $_->property_name !~ /id$/
} RefImp::Tenx::Reference->__meta__->properties;

class RefImp::Tenx::Command::Reference::Create { 
    is => 'Command::V2',
    has_input => \%inputs,
    doc => 'create a longranger reference db entry',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 
    $self->status_message('Create longranger reference...');

    my %params = map { $_ => $self->$_ } keys %inputs;
    $params{directory} = dir($params{directory})->absolute->stringify;
    $self->fatal_message('Directory %s does not exist!', $params{directory}) if !-d $params{directory};
    $self->status_message("Params:\n%s", YAML::Dump( {map { $_ => ( ref $params{$_} ? $params{$_}->id : $params{$_} ) } keys %params }));
    my $reference = RefImp::Tenx::Reference->create(%params);
    $self->status_message('Created reference: %s', $reference->__display_name__);

    1;
}

1;