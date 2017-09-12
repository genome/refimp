package Refimp::Assembly::Command::Submission::Yaml;

use strict;
use warnings;

use Refimp::Assembly::SubmissionInfo;
use YAML;

class Refimp::Assembly::Command::Submission::Yaml {
    is => 'Command::V2',
    doc => 'print submission yaml to fill out',
};

sub help_detail {
    my $help = <<HELP;
Save this YAML to a file named 'submission.yml' in the submission directory. It will be the input into the assembly submit command.

Fill in or remove unneeded fields. All fields that remain in the YAML must be defined.

Files should not include the directory. The submission directory is automatically prepended to the file names.

Submission Info Field Docs

HELP
    $help .= Refimp::Assembly::SubmissionInfo->help_doc_for_attributes;
    $help;
}

sub execute {
    my $self = shift;

    my %h = Refimp::Assembly::SubmissionInfo->submission_yaml;
    my $string = YAML::Dump(\%h);
    $string =~ s/'//g;
    print $string;
}

1;
