package RefImp::Assembly::SubmissionInfo;

use strict;
use warnings;

use Params::Validate qw/ :types validate_pos /;
use YAML;

my %submission_info = (
    assembly_method => {
        required => 1,
        structured_comment => 1,
        doc => 'The assembler used to create the assembly.',
        example => 'Falcon January 2017',
    },
    assembly_name => {
        required => 0,
        structured_comment => 1,
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
    genome_coverage => {
        required => 1,
        structured_comment => 1,
        doc => 'The approximate coverage of the genome. Expressed with an "X".',
        example => '87X',
    },
    long_assembly_name => {
        required => 0,
        structured_comment => 1,
        doc => ' The long/descriptive assembly name.',
        example => 'NA19240 Illumina assembly version 1',
    },
    polishing_method => {
        required => 0,
        structured_comment => 1,
        doc => 'The assembly improvement methods, separated by a semicolon.',
        example => 'Quiver; Pilon',
    },
    release_date => {
        required => 1,
        structured_comment => 1,
        value => 'immediately after processing',
        doc => "There are 2 NCBI standard, or set your own.",
        example => join(" or ", valid_release_dates()),
    },
    release_notes_file => {
        required => 1,
        doc => 'File name (without directory) containing unstuctured comments.',
    },
    sequencing_technology => {
        required => 1,
        structured_comment => 1,
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
    tbl2asn_params => {
        requried => 0,
        doc => 'Addition parameters to pass into the tbl2asn command. Typically, this will be to decribe how gaps were confirmed, but any parameter can be added. The example show gaps were determined by read pairs and FASTA with Gap Lines. See "tbl2asn --help for more options.',
        example => '-a z -l paired-ends',
    },
    version => {
        required => 1,
        doc => 'The version of the assembly. This will be combined with the taxon to make the NCBI version.',
        example => '2.0',
    },
);

sub default_release_date { (valid_release_dates())[0] }
sub valid_release_dates { ( 'immediately after processing', 'hold until publication', '\d{2}-\d{2}-\d{4}' ) }
sub valid_release_date_regexps { map { qr/^$_$/ } valid_release_dates() }

sub submission_yaml { my %h = map { my $v = $submission_info{$_}->{value} // ''; ($_, $v) } submission_info_keys(); %h }
sub submission_info_keys { sort keys %submission_info }
sub submission_info_optional_keys { grep { !$submission_info{$_}->{required} } submission_info_keys() }

sub required_attributes_for_structured_comments {
    my $class = shift;

    my @attrs;
    for my $key ( submission_info_keys() ) {
        push @attrs, $key if exists $submission_info{$key}->{structured_comment} and $submission_info{$key}->{required};
    }
    @attrs;
}

sub optional_attributes_for_structured_comments {
    my $class = shift;

    my @attrs;
    for my $key ( submission_info_keys() ) {
        push @attrs, $key if exists $submission_info{$key}->{structured_comment} and not $submission_info{$key}->{required};
    }
    @attrs;
}

sub help_doc_for_attribute {
    my ($class, $key) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    my $attribute = $submission_info{$key};
    die "No submission attribute for $key" if not $attribute;

    sprintf(
            "%s [%s]\n\n  %s%s\n\n",
            # Name
            join(' ', map { ucfirst } split(/_/, $key)),
            # Required?
            ( $attribute->{required} ? 'required' : 'optional' ),
            # Doc
            $attribute->{doc},
            # Example
            ( $attribute->{example} ? sprintf(" Example: %s\n", $attribute->{example}) : '' ),
    );
}

sub help_doc_for_attributes {
    my $class = shift;
    my $help = "Submission Info Field Docs\n\n";
    for my $key ( submission_info_keys() ) {
        $help .= $class->help_doc_for_attribute($key);
    }
    $help;
}

1;
