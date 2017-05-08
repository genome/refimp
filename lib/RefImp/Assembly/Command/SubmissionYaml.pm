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
Save this YAML to a file named 'submission.myl' in the submission directory. It will be the input into the assembly submit commmand.

Each field is required. Here are notes on some of the required fields.

Assembly Method
  The assembler used to create the assembly.
  Example
    Falcon January 2017

Authors

  Comma separated list of names. Include first name, middle intials [optional], and last name.
  Example:
    Barack H Obama,Joe Biden

Coverage 
  The approximate coverage of the genome. Expressed with an 'X'.
  Example
    87X

Release Date 

  There are 2 NCBI standard, or set your own. Valid values/formats:

$valid_release_dates

Sequenceing Technology
  The read type. Sequencing machine and chemistry
  Example
    PacBio_RSII

Taxon
  The NCBI taxon species name. It must exist in our DB. Create with 'ref-imp taxon create'.
  Example:
    Crassostrea virginica

Version

  The version of the assembly. This will be combined with the taxon to make the NCBI version.
  Example:
    Crassostrea_virginica_2.0

HELP
}

my %submission_info = (
    assembly_method => '',
    authors => '',
    agp_file => '',
    bioproject => '',
    biosample => '',
    contigs_file => '',
    coverage => '',
    polishing_method => 'NA',
    release_date => 'immediately after processing',
    release_notes_file => '',
    sequencing_technology => '',
    supercontigs_file => '',
    taxon => '',
    version => '',
);
sub submission_info_hash { %submission_info }
sub submission_info_keys { sort keys %submission_info }

sub execute {
    my $self = shift;

    my $string = YAML::Dump( {submission_info_hash()} );
    $string =~ s/'//g;
    print $string;
}

1;
