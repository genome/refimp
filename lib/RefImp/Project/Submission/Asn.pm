package RefImp::Project::Submission::Asn;

use strict;
use warnings 'FATAL';

use Bio::SeqIO;
use File::Spec;
use List::Util;
use RefImp::Resources::Ncbi::ProjectName;

class RefImp::Project::Submission::Asn {
    has => {
        project => { is => 'RefImp::Project', },
        submit_info => { is => 'HASH', },
        working_directory => { is => 'Text', },
    },
    has_calculated => {
        ncbi_clone_name => {
            calculate_from => [qw/ project /],
            calculate => q/ RefImp::Resources::Ncbi::ProjectName->get($project->name) /,
        },
        template_path => {
            calculate_from => [qw/ project working_directory /],
            calculate => q/ File::Spec->join($working_directory, join('.', $project->name, 'template')) /,
        },
        asn_path => {
            calculate_from => [qw/ working_directory project /],
            calculate => q/ File::Spec->join($working_directory, join('.', $project->name, 'sqn')) /,
        },
    },
    has_transient_optional => {
        header => { is => 'Text', },
    },
};

sub generate {
    my $self = shift;

    $self->_create_header;
    $self->_create_tbl_file;
    $self->_create_template_file;
    $self->_create_fsa_file;
    $self->_create_asn_file;

    return 1;
}

sub _create_header {
    my $self = shift;
    $self->status_message('Create header...');

    my $project = $self->project;
    my @submissions = $project->submissions;
    my $submission = List::Util::first {  $_->phase eq '3' } @submissions;
    my $primary_accession = ( $submission ? $submission->accession_id : undef );
    my $secondary_accession = undef;

    my $chromosome = $self->project->taxonomy->chromosome;
    my $clone_type = uc $project->clone_type;
    my $gb_clone_name = $self->ncbi_clone_name;
    my $species_name = $self->project->taxon->species_name;

    my $header;
    if (! defined ($primary_accession)){
        $header = qq{gnl|wugsc|$gb_clone_name};
    }
    else{
        $header = qq{gb|$primary_accession||gnl|wugsc|$gb_clone_name};
    }

    if (defined($secondary_accession)) {
        $header = qq{$header [secondary-accession=$secondary_accession]};
    };

    $header = "$header [chromosome=$chromosome] [Clone-lib=]";
    $header = qq{$header [clone=$gb_clone_name] [tech=htgs 3] $species_name $clone_type};
    $header = qq{$header clone $gb_clone_name from chromosome $chromosome, complete sequence.};

    $self->header($header);
    $self->status_message('Create header...OK');
}

sub _create_tbl_file {
    my $self = shift;
    $self->status_message('Create TBL file...');

    my $tbl_path = File::Spec->join($self->working_directory, join('.', $self->project->name, 'tbl'));
    $self->status_message('TBL path: %s', $tbl_path);
    my $fh = IO::File->new($tbl_path, 'w');
    $self->fatal_message('Failed to open TBL file! %s', $!) if not $fh;

    print $fh ">Feature ".$self->header."\n";

    my ($trpdiff,$trpstartbase,$trpendbase,$commentendbase);
    my $ref = $self->submit_info;
    if (defined ($ref->{COMMENTS}->{TransposonComments})){
        foreach (@{$ref->{COMMENTS}->{TransposonComments}}) {
            if ($_->{TransposonCommentsSequenceRegion} =~ /^finished/i) {
                $trpstartbase = $_->{TransposonCommentsLastBaseBeforePosition};
                $trpendbase = $_->{TransposonCommentsFirstBaseAfterPosition};
                $commentendbase = $trpstartbase + 1;
                $trpdiff = $trpendbase - $trpstartbase - 1;

                print $fh "$trpstartbase\t$commentendbase\tmisc_feature\n";
                print $fh "\t\t\tnote\tBacterial transposon insertion in clone excised here\n";
            }
        }
    }
    if (defined ($ref->{COMMENTS}->{PCROnlyRegionsComments})){
        foreach (@{$ref->{COMMENTS}->{PCROnlyRegionsComments}}) {
            my $startbase = $_->{PCROnlyRegionsCommentsRegionFrom};
            my $endbase = $_->{PCROnlyRegionsCommentsRegionTo};
            my $dnasource = $_->{PCROnlyRegionsCommentsDNASource};
            $dnasource =~ s/\bdna\b/DNA/;
            if ($trpdiff && ($startbase > $trpstartbase)) {
                $startbase = $startbase - $trpdiff;
                $endbase = $endbase - $trpdiff;
            }
            print $fh "$startbase\t$endbase\tmisc_feature\n";
            print $fh "\t\t\tnote\tSequence derived from PCR product of $dnasource\n";
        }
    }

    if (defined ($ref->{COMMENTS}->{SingleCloneCoverageComments})){
        foreach (@{$ref->{COMMENTS}->{SingleCloneCoverageComments}}) {
            my $startbase =$_->{SingleCloneCoverageCommentsStartBP};
            my $endbase = $_->{SingleCloneCoverageCommentsEndBP};
            my $subclonetype = lc $_->{SingleCloneCoverageSubcloneType};
            if ($trpdiff && ($startbase > $trpstartbase)) {
                $startbase = $startbase - $trpdiff;
                $endbase = $endbase - $trpdiff;
            }

            print $fh "$startbase\t$endbase\tunsure\n";
            print $fh "\t\t\tnote\tSequence derived from one $subclonetype subclone.\n";
        }
    }

    if  (defined ($ref->{COMMENTS}->{UnsureBasecallComments})){
        foreach (@{$ref->{COMMENTS}->{UnsureBasecallComments}}) {
            my $startbase = $_->{ UnsureBasecallCommentsStartBP};
            my $endbase = $_->{ UnsureBasecallCommentsEndBP};
            if ($trpdiff && ($startbase > $trpstartbase)) {
                $startbase = $startbase - $trpdiff;
                $endbase = $endbase - $trpdiff;
            }
            print $fh "$startbase\t$endbase\tunsure\n";
            print $fh "\t\t\tnote\tUnresolved bases\n";
        }
    }

    if (defined ($ref->{COMMENTS}->{HomopolymericRunComments})){
        foreach (@{$ref->{COMMENTS}->{HomopolymericRunComments}}) {
            my $startbase = $_->{HomopolymericRunCommentsStartBP};
            my $endbase = $_->{HomopolymericRunCommentsEndBP};
            if ($trpdiff && ($startbase > $trpstartbase)) {
                $startbase = $startbase - $trpdiff;
                $endbase = $endbase - $trpdiff;
            }
            print $fh "$startbase\t$endbase\tmisc_feature\n";
            print $fh "\t\t\tnote\tUnresolved homopolymeric repeat.\n";
        }
    }

    if (defined ($ref->{COMMENTS}->{UnresolvedTandemRepeatsComments})){
        foreach (@{$ref->{COMMENTS}->{UnresolvedTandemRepeatsComments}}) {
            my $startbase = $_->{UnresolvedTandemRepeatsCommentsStartBP};
            my $endbase = $_->{UnresolvedTandemRepeatsCommentsEndBP};
            if ($trpdiff && ($startbase > $trpstartbase)) {
                $startbase = $startbase - $trpdiff;
                $endbase = $endbase - $trpdiff;
            }
            print $fh "$startbase\t$endbase\tunsure\n";
            print $fh "\t\t\tnote\tUnresolved tandem repeat.\n";
        }
    }

    if (defined ($ref->{COMMENTS}->{UnresolvedDiTriRepeatsComments})){
        foreach (@{$ref->{COMMENTS}->{UnresolvedDiTriRepeatsComments}}) {
            my $startbase = $_->{UnresolvedDiTriRepeatsCommentsStartBP};
            my $endbase = $_->{UnresolvedDiTriRepeatsCommentsEndBP};
            if ($trpdiff && ($startbase > $trpstartbase)) {
                $startbase = $startbase - $trpdiff;
                $endbase = $endbase - $trpdiff;
            }
            print $fh "$startbase\t$endbase\tunsure\n";
            print $fh "\t\t\tnote\tUnresolved simple sequence repeat.\n";
        }
    }

    if (defined ($ref->{COMMENTS}->{UnresolvedLargeDuplicationsComments})){
        foreach (@{$ref->{COMMENTS}->{UnresolvedLargeDuplicationsComments}}) {
            my $startbase = $_->{UnresolvedLargeDuplicationsCommentsStartBP};
            my $endbase = $_->{UnresolvedLargeDuplicationsCommentsEndBP};
            if ($trpdiff && ($startbase > $trpstartbase)) {
                $startbase = $startbase - $trpdiff;
                $endbase = $endbase - $trpdiff;
            }
            print $fh "$startbase\t$endbase\tunsure\n";
            print $fh "\t\t\tnote\tUnresolved duplication.\n";
        }
    }

    if (defined ($ref->{COMMENTS}->{UnresolvedInvertedRepeatsComments})){
        foreach (@{$ref->{COMMENTS}->{UnresolvedInvertedRepeatsComments}}) {
            my $startbase = $_->{UnresolvedInvertedRepeatsCommentsStartBP};
            my $endbase = $_->{UnresolvedInvertedRepeatsCommentsEndBP};
            if ($trpdiff && ($startbase > $trpstartbase)) {
                $startbase = $startbase - $trpdiff;
                $endbase = $endbase - $trpdiff;
            }
            print $fh "$startbase\t$endbase\tunsure\n";
            print $fh "\t\t\tnote\tUnresolved inverted repeat.\n";
        }

    }
    $fh->close;

    $self->status_message('Create TBL file...OK');
}

sub _create_template_file {
    my $self = shift;
    $self->status_message('Create template file...');

    my $ref = $self->submit_info;

    my @author_names;
    foreach my $author_key (qw/ FinisherUserList PrefinisherUserList SaverUserList /) {
        push @author_names, @{$ref->{GENINFO}->{$author_key}} if $ref->{GENINFO}->{$author_key};
    }
    my @authors = map { RefImp::User->get(name => $_) } @author_names;

    my @othercomments;
    if (defined ($ref->{COMMENTS}->{TransposonComments})){
        foreach (@{$ref->{COMMENTS}->{TransposonComments}}) {
            if ($_->{TransposonCommentsSequenceRegion} =~ /vector/i) {
                push @othercomments, "Bacterial transposon in vector portion of the clone.";
            }
        }
    }

    my $raw_template_path = RefImp::Project::Submission->raw_sqn_template_for_taxon($self->project->taxon);
    $self->status_message('Raw template path: %s', $raw_template_path);
    my $rawfh = IO::File->new($raw_template_path, 'r');
    $self->fatal_message('Failed to open raw template path! %s', $!) if not $rawfh;

    my $template_path = $self->template_path;
    $self->status_message('Template path: %s', $template_path);
    my $fh = IO::File->new($template_path, 'w');
    $self->fatal_message('Failed to open template path! %s', $!) if not $fh;

    while (my $Line = <$rawfh>) {
        unless(($Line =~ /ANYTHINGELSE|MAPINFORMATION|SUMMARYSTATISTICS|SOURCEINFORMATION|ENTERFINISHERS/)){
            print $fh "$Line";
        }
        if($Line =~ /MAPINFORMATION/) {
            $Line =~ s/MAPINFORMATION//;
            print $fh $Line;
        }
        if($Line =~ /SOURCEINFORMATION/) {
            $Line =~ s/SOURCEINFORMATION//;
            print $fh $Line;
            print $fh undef;
        }

        if($Line =~ /SUMMARYSTATISTICS/) {
            $Line =~ s/SUMMARYSTATISTICS//;
            print $fh $Line;
            print $fh $self->project->name."~";
        }

        if($Line =~ /ANYTHINGELSE/) {
            $Line =~ s/ANYTHINGELSE/~~/;
            print $fh $Line;
            print $fh "This sequence is the entire insert of the clone.\n";
            if (@othercomments ){
                print $fh $Line;
                print $fh "OTHER INFORMATION:~\n";
                print $fh @othercomments;}
        }
        if($Line =~ /ENTERFINISHERS/) {
            $Line =~ s/ENTERFINISHERS/\n/;
            print $fh $Line;
            print $fh  "Seqdesc ::= pub { \n";
            print $fh  " pub { \n";
            print $fh  "  gen { \n";
            print $fh  "   cit \"Unpublished\" , \n";
            print $fh  "   authors { \n";
            print $fh  "    names \n";
            print $fh  "     std { \n";

            my $author_format =
                "      { \n".
                "       name \n".
                "        name { \n".
                "         last \"%s\" , \n".
                "         initials \"%s.\" } }";# , \n";
            print $fh join(" , \n", map{
                    sprintf($author_format, $_->last_name_uc, $_->first_initial)
                } @authors
            );
            print $fh " } } ,\n";

            printf(
                $fh  "   title \"The sequence of %s %s clone %s\" } } } \n",
                $self->project->taxon->species_name, uc($self->project->clone_type), $self->ncbi_clone_name,
            );
        } 

    }

    $rawfh->close;
    $fh->close;

    $self->status_message('Create template file...OK');
}

sub _create_fsa_file { # header on first line, entire sequence on second line
    my $self = shift;
    $self->status_message('Create FSA file...');

    my $seqfile = File::Spec->join($self->working_directory, join('.', $self->project->name, 'seq'));
    $self->status_message('Getting sequence from SEQ file: %s', $seqfile);
    my $seqstream = Bio::SeqIO->new('-file' => $seqfile, '-format' => 'Fasta');
    my $seq = $seqstream->next_seq()->seq;

    my $fsa_path = File::Spec->join($self->working_directory, join('.', $self->project->name, 'fsa'));
    $self->status_message('FSA path: %s', $fsa_path);
    my $fh = new IO::File ">$fsa_path";
    $fh->print( ">".$self->header."\n".$seq);
    $fh->close;

    $self->status_message('Create FSA file...OK');
}

sub _create_asn_file {
    my $self = shift;
    $self->status_message('Create ASN file...');

    my $species_name = $self->project->taxon->species_name;
    my $asn_path = $self->asn_path;
    $self->status_message('ASN file: %s', $asn_path);
    my $template_path = $self->template_path;
    my $working_directory = $self->working_directory;

    my $tbl2asn = "tbl2asn.linux64";
    my $cmd = "$tbl2asn -t $template_path  -p $working_directory -j '[organism=$species_name]'";
    $self->status_message('Running: %s', $cmd);
    my $rv = system $cmd;
    if ( $rv or not -s $asn_path ) {
        $self->fatal_message('Failed to create ASN file!');
    }

    $self->status_message('Create ASN file...OK');
}

1;

