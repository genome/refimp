package RefImp::Assembly::Command::Submission::Yaml;

use strict;
use warnings 'FATAL';

use RefImp::Assembly::SubmissionInfo;
use YAML;

class RefImp::Assembly::Command::Submission::Yaml {
    is => 'Command::V2',
    doc => 'print submission yaml template to fill out',
};

sub help_detail { "Print the submission YAML template to use when submitting am assembly. For detailed info, use 'refimp assembly submission info' command." }

sub execute {
    my %h = RefImp::Assembly::SubmissionInfo->submission_yaml;
    my $string = YAML::Dump(\%h);
    $string =~ s/'//g;
    print $string;
}

1;
