package RefImp::Assembly::Command::Submission::Yaml;

use strict;
use warnings;

use RefImp::Assembly::Submission;
use RefImp::Assembly::SubmissionInfo;
use YAML;

class RefImp::Assembly::Command::Submission::Yaml {
    is => 'Command::V2',
    doc => 'print submission yaml to fill out',
};

sub help_detail {
    my $help = <<HELP;
Save this YAML to a file named 'submission.myl' in the submission directory. It will be the input into the assembly submit commmand.

Fill in or remove unneeded fields. All fields that remain in the YAML must be defined.

Files should not include the directory. The submission directory is automatically prepended to the file names.

Submission Info Field Docs

HELP
    $help .= RefImp::Assembly::SubmissionInfo->help_doc_for_attributes;
    $help;
}

sub execute {
    my $self = shift;

    my %h = RefImp::Assembly::SubmissionInfo->submission_yaml;
    my $string = YAML::Dump(\%h);
    $string =~ s/'//g;
    print $string;
}

1;
