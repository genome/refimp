package RefImp::Assembly::Command::Submission::Yaml;

use strict;
use warnings;

use YAML;

class RefImp::Assembly::Command::Submission::Yaml {
    is => 'Command::V2',
    doc => 'print submission yaml to fill out',
};

my %submission_info = (
    assembly_method => {
        required => 1,
        doc => 'The assembler used to create the assembly.',
        example => 'Falcon January 2017',
    },
    assembly_name => {
        required => 0,
        doc => 'The brief/short assembly name. This is a short name suitable for display that does not include the organism name.',
        example => 'NA19240_Illumina_1.0',
    },
    authors => {
        required => 1,
        doc => 'Semicolon separated list of names. Include first name, middle intials [optional, must have periods], and last name.',
        example => 'Barack H. Obama; Joe Biden',
    },
    agp_file => {
        required => 0,
        doc => 'The file name (without directory) of the AGP file. Include only as supplement to a contigs file. Do NOT include with supercontigs.',
    },
    bioproject => {
        required => 1,
        doc => 'NCBI issued project.',
        example => 'PRJNA376014',
    },
    biosample => {
        required => 1,
        doc => 'The NCBI issues biosample.',
        example => 'SAMN06349363',
    },
    contact => {
        required => 1, 
        value => 'Richard K. Wilson',
        doc => 'The contact person',
        example => 'Richard K. Wilson',
    },
    contigs_file => {
        required => 0,
        doc => 'The file name (without directory) of the contigs fasta file. OPtionally include an AGP file. Do NOT include a supercontigs file.',
    },
    coverage => {
        required => 1,
        doc => 'The approximate coverage of the genome. Expressed with an "X".',
        example => '87X',
    },
    long_assembly_name => {
        required => 0,
        doc => ' he long/descriptive  assembly name.',
        example => 'NA19240 Illumina assembly version 1',
    },
    polishing_method => {
        required => 0,
        doc => 'The assembly improvement methods, separated by a semicolon.',
        example => 'Quiver; Pilon',
    },
    release_date => {
        required => 1,
        value => 'immediately after processing',
        doc => "There are 2 NCBI standard, or set your own.",
        example => join(" or ", RefImp::Assembly::Submission->valid_release_dates),
    },
    release_notes_file => {
        required => 1,
        doc => 'File name (without directory) containing unstuctured comments.',
    },
    sequencing_technology => {
        required => 1,
        doc => 'The read type. Sequencing machine and chemistry.',
        example => 'PacBio_RSII',
    },
    supercontigs_file => {
        required => 1,
        doc => 'The file name (without directory) of the supercontigs fasta file. Include as th fasta file for submission. Do NOT include contigs or AGP files.',
    },
    taxon => {
        required => 1,
        doc => "The NCBI taxon species name. It must exist in our DB. Create with 'ref-imp taxon create'.",
        example => 'Crassostrea virginica'
    },
    version => {
        required => 1,
        doc => 'The version of the assembly. This will be combined with the taxon to make the NCBI version.',
        example => '2.0',
    },
);

sub submission_info_hash { my %h = map { my $v = $submission_info{$_}->{value} // ''; ($_, $v) } submission_info_keys(); %h }
sub submission_info_keys { sort keys %submission_info }
sub submission_info_optional_keys { grep { !$submission_info{$_}->{required} } submission_info_keys() }

sub help_detail {
    my $help = <<HELP;
Save this YAML to a file named 'submission.myl' in the submission directory. It will be the input into the assembly submit commmand.

Fill in or remove unneeded fields. All fields that remain in the YAML must be defined.

Files should not include the directory. The submission directory is automatically prepended to the file names.

Submission Info Field Docs

HELP
    for my $key ( submission_info_keys() ) {
        $help .= sprintf(
            "%s [%s]\n\n  %s%s\n\n",
            # Name
            join(' ', map { ucfirst } split(/_/, $key)),
            # Required?
            ( $submission_info{$key}->{required} ? 'required' : 'optional' ),
            # Doc
            $submission_info{$key}->{doc},
            # Example
            ( $submission_info{$key}->{example} ? sprintf(" Example: %s\n", $submission_info{$key}->{example}) : '' ),
        );
    }
    $help;
}

sub execute {
    my $self = shift;

    my $string = YAML::Dump( {submission_info_hash()} );
    $string =~ s/'//g;
    print $string;
}

1;
