package RefImp::Assembly::Command::Submission::Yaml;

use strict;
use warnings;

use YAML;

class RefImp::Assembly::Command::Submission::Yaml {
    is => 'Command::V2',
    doc => 'print submission yaml to fill out',
};

sub help_detail {
    my $valid_release_dates = join("\n\n", ,map { "  $_" } RefImp::Assembly::Submission->valid_release_dates);
<<HELP;
Save this YAML to a file named 'submission.myl' in the submission directory. It will be the input into the assembly submit commmand.

Fill in or remove unneeded fields. All fields that remain in the YAML must be defined.

Files should not include the directory. The submission directory is automatically prepended to the file names.

Here are notes on some of the required fields:

Assembly Method [required]

  The assembler used to create the assembly.
  Example
    Falcon January 2017

Authors [required]

  Comma separated list of names. Include first name, middle intials [optional, must have periods], and last name.
  Example:
    Barack H. Obama,Joe Biden

Bioproject [required]

  NCBI issue project.
  Example
    PRJNA376014

Biosample [required]

  NCBI issused sample.
  Example
    SAMN06349363

Contact [required]

  Name of contact here at the MGI. Default is RW.
  Example
    Richard K. Wilson

Coverage [required]

  The approximate coverage of the genome. Expressed with an 'X'.
  Example
    87X


Polishing Method [optional]

  The assembly improvement methods, separated by a semicolon.
  Example
    Quiver; Pilon

Release Date  [required]

  There are 2 NCBI standard, or set your own. Valid values/formats:

$valid_release_dates

Sequencing Files

  As fasta format file of sequences is required. Include a contigs_file OR supercontigs_file in fasta format. An optional agp_file for the contigs_file can be included. Do not include both contigs_file and superconting_file. Also, do not include an agp_file with supercontigs_file.

Sequencing Technology [required]

  The read type. Sequencing machine and chemistry.
  Example
    PacBio_RSII

Taxon [required]

  The NCBI taxon species name. It must exist in our DB. Create with 'ref-imp taxon create'.
  Example:
    Crassostrea virginica

Version [required]

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
    contact => 'Richard K. Wilson',
    contigs_file => '',
    coverage => '',
    polishing_method => '',
    release_date => 'immediately after processing',
    release_notes_file => '',
    sequencing_technology => '',
    supercontigs_file => '',
    taxon => '',
    version => '',
);
sub submission_info_hash { %submission_info }
sub submission_info_keys { sort keys %submission_info }
sub submission_info_optional_keys { ( 'polishing_method' ) }

sub execute {
    my $self = shift;

    my $string = YAML::Dump( {submission_info_hash()} );
    $string =~ s/'//g;
    print $string;
}

1;
