package Tenx::Alignment::Command::CreateFromDirectory;

use strict;
use warnings 'FATAL';

use List::MoreUtils;
use File::Slurp;
use Path::Class;
use YAML;

use RefImp::Alignment;
my %inputs = map {
        $_->property_name => {
            is => $_->data_type,
            is_optional => $_->is_optional,
            shell_args_position => 1,
            doc => $_->doc,
        }
} RefImp::Alignment->__meta__->property_meta_for_name('url');

class Tenx::Alignment::Command::CreateFromDirectory { 
    is => 'Command::V2',
    has_input => \%inputs,
    doc => 'create a longranger alignment db entry from a url.',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift; 
    $self->status_message('Create longranger alignment from url...');

    my $url = dir($self->url)->absolute;
    $self->fatal_message('URL %s does not exist!', $url) if !-d "$url";

    my $alignment = RefImp::Alignment->get(url => "$url");
    $self->fatal_message('Found existing alignment for url %s', $alignment->__display_name__) if $alignment;

    my $params = $self->_resolve_params_from_url($url);
    $params->{url} = "$url";
    $self->status_message("Params:\n%s", YAML::Dump( {map { $_ => ( ref $params->{$_} ? $params->{$_}->id : $params->{$_} ) } keys %$params }));
    $alignment = RefImp::Alignment->create(%$params);
    $self->status_message('Created alignment %s', $alignment->__display_name__);

    1;
}

sub _resolve_params_from_url {
    my ($self, $url) = @_;

    my $invocation_file = $url->file('_invocation');
    $self->fatal_message('Cannot find "_invocation" file in %s', $url) if not -s "$invocation_file";

    my @invocation_contents = File::Slurp::slurp($invocation_file->stringify);

    my $val = List::MoreUtils::firstval { /read_path/ } @invocation_contents;
    $self->fatal_message('No read_path in invocation file!', $invocation_file) if not $val;
    my (undef, $reads_directory) = split(/\s*:\s*/, $val, 2);
    chomp $reads_directory;
    $reads_directory =~ s/[",]//g;
    $reads_directory = dir( $reads_directory )->absolute;
    my $reads = RefImp::Reads->get(url => "$reads_directory");
    $self->fatal_message('No reads found for directory! %s', $reads_directory) if not $reads;

    $val = List::MoreUtils::firstval { /reference_path/ } @invocation_contents;
    $self->fatal_message('No reference_path in invocation file!', $invocation_file) if not $val;
    my (undef, $ref_directory) = split(/\s*=\s*/, $val, 2);
    chomp $ref_directory;
    $ref_directory =~ s/[",]//g;
    $ref_directory = dir( $ref_directory )->absolute;
    my $ref = RefImp::Refseq->get(url => "$ref_directory");
    $self->fatal_message('No reference found for directory! %s', $ref_directory) if not $ref;

    { reads => $reads, refseq => $ref, };
}

1;
