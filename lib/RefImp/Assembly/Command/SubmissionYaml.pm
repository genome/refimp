package RefImp::Assembly::Command::SubmissionYaml;

use strict;
use warnings;

use YAML;

class RefImp::Assembly::Command::SubmissionYaml {
    is => 'Command::V2',
    doc => 'print submission yaml to fill out',
};

sub help_detail {
    my $valid_release_dates = join("\n\n", ,map { "  $_" } RefImp::Assembly::Submission->valid_release_dates);
<<HELP;
Notes on some of the required fields.

Authors

  Comma separated list of names. Include first name, middle intials [optional], and last name.
  Example:
    Barack H Obama,Joe Biden

Release Date 

  There are 2 NCBI standard, or set your own. Valid values/formats:

$valid_release_dates

Version

  The version should be the genus name, species name and the vesion. These are separarted by an underscore.
  Example:
    Crassostrea_virginica_2.0


HELP
}


sub execute {
    my $self = shift;

    my %submission = (
        assembler => '',
        authors => '',
        agp_file => '',
        bioproject => '',
        biosample => '',
        contigs_file => '',
        coverage => '',
        read_type => '',
        release_date => 'immediately after processing',
        release_notes_file => '',
        supercontigs_file => '',
        version => '',
    );

    my $string = YAML::Dump(\%submission);
    $string =~ s/'//g;
    print $string;
}

1;
