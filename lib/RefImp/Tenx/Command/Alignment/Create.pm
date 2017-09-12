package Refimp::Tenx::Command::Alignment::Create;

use strict;
use warnings;

use Path::Class;

use Refimp::Tenx::Alignment;
my %inputs = map {
        $_->property_name => {
            is => $_->data_type,
            is_optional => $_->is_optional,
            doc => $_->doc,
        }
    } grep {
        $_->property_name !~ /id$/
} Refimp::Tenx::Alignment->__meta__->properties;

class Refimp::Tenx::Command::Alignment::Create { 
    is => 'Command::V2',
    has_input => \%inputs,
    doc => 'create a longranger alignment db entry',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 
    $self->status_message('Create longranger alignment...');

    my %params = map { $_ => $self->$_ } keys %inputs;
    $params{directory} = dir($params{directory})->absolute->stringify;
    $self->fatal_message('Directory %s does not exist!', $params{directory}) if !-d $params{directory};

    my $alignment = Refimp::Tenx::Alignment->get(directory => $params{directory});
    $self->fatal_message('Found existing alignment for directory: %s', $alignment->__display_name__) if $alignment;

    $self->status_message("Params:\n%s", YAML::Dump( {map { $_ => ( ref $params{$_} ? $params{$_}->id : $params{$_} ) } keys %params }));
    $alignment = Refimp::Tenx::Alignment->create(%params);
    $self->status_message('Created alignment %s', $alignment->__display_name__);

    1;
}

1;
