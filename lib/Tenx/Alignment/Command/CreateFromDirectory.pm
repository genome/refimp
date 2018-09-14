package Tenx::Alignment::Command::CreateFromDirectory;

use strict;
use warnings 'FATAL';

use List::MoreUtils;
use File::Slurp;
use Path::Class;
use YAML;

use Tenx::Alignment;
my %inputs = map {
        $_->property_name => {
            is => $_->data_type,
            is_optional => $_->is_optional,
            shell_args_position => 1,
            doc => $_->doc,
        }
} Tenx::Alignment->__meta__->property_meta_for_name('directory');

class Tenx::Alignment::Command::CreateFromDirectory { 
    is => 'Command::V2',
    has_input => \%inputs,
    doc => 'create a longranger alignment db entry from a directory',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 
    $self->status_message('Create longranger alignment from directory...');

    my $directory = dir($self->directory)->absolute;
    $self->fatal_message('Directory %s does not exist!', $directory) if !-d "$directory";

    my $alignment = Tenx::Alignment->get(directory => "$directory");
    $self->fatal_message('Found existing alignment for directory: %s', $alignment->__display_name__) if $alignment;

    my $params = $self->_resolve_params_from_directory($directory);
    $params->{directory} = "$directory";
    $self->status_message("Params:\n%s", YAML::Dump( {map { $_ => ( ref $params->{$_} ? $params->{$_}->id : $params->{$_} ) } keys %$params }));
    $alignment = Tenx::Alignment->create(%$params);
    $self->status_message('Created alignment %s', $alignment->__display_name__);

    1;
}

sub _resolve_params_from_directory {
    my ($self, $directory) = @_;

    my $invocation_file = $directory->file('_invocation');
    $self->fatal_message('Cannot find "_invocation" file in %s', $directory) if not -s "$invocation_file";

    my @invocation_contents = File::Slurp::slurp($invocation_file->stringify);

    my $val = List::MoreUtils::firstval { /read_path/ } @invocation_contents;
    $self->fatal_message('No read_path in invocation file!', $invocation_file) if not $val;
    my (undef, $reads_directory) = split(/\s*:\s*/, $val, 2);
    chomp $reads_directory;
    $reads_directory =~ s/[",]//g;
    $reads_directory = dir( $reads_directory )->absolute;
    my $reads = Tenx::Reads->get(directory => "$reads_directory");
    $self->fatal_message('No reads found for directory! %s', $reads_directory) if not $reads;

    $val = List::MoreUtils::firstval { /reference_path/ } @invocation_contents;
    $self->fatal_message('No reference_path in invocation file!', $invocation_file) if not $val;
    my (undef, $ref_directory) = split(/\s*=\s*/, $val, 2);
    chomp $ref_directory;
    $ref_directory =~ s/[",]//g;
    $ref_directory = dir( $ref_directory )->absolute;
    my $ref = Tenx::Reference->get(directory => "$ref_directory");
    $self->fatal_message('No reference found for directory! %s', $ref_directory) if not $ref;

    { reads => $reads, reference => $ref, };
}

1;
