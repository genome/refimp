package RefImp::Clone::Submissions::Form;

use strict;
use warnings;

use Params::Validate ':types';

sub create {
    my ($class, $hash) = Params::Validate::validate_pos(@_, {isa => __PACKAGE__}, {type => HASHREF});

    my $geninfo = $hash->{GENINFO};

    textifyNameList( $geninfo, "FinisherUserList", "FinisherUserListExpanded" );
    textifyNameList( $geninfo, "PrefinisherUserList",
        "PrefinisherUserListExpanded" );
    textifyNameList( $geninfo, "SaverUserList", "SaverUserListExpanded" );

    my @output;
    push @output,
    "CLONE NAME IS:\t\t\t\t"
    . $geninfo->{"CloneName"} . " "
    . ($geninfo->{"CloneAccession"} || '');
    push @output, "FINISHER'S USER NAME IS: \t\t\t"
    . $geninfo->{"FinisherUserListExpanded"};
    push @output,
    "PERSON WHO SAVED PROJECT:\t\t\t" . $geninfo->{"SaverUserListExpanded"};
    push @output, "PERSON WHO PRE-FINISHED PROJECT:\t\t"
    . $geninfo->{"PrefinisherUserListExpanded"};
    push @output, "FINISHER'S GROUP IS:\t\t\t\t" . $geninfo->{"FinishingGroup"};
    push @output,
    "PRODUCTION GROUP IS:\t\t\t\t" . $geninfo->{"ProductionGroup"};
    push @output,
    "COMPLETION DATE OF CLONE IS:\t\t\t";
    push @output, "ORGANISM BEING SUBMITTED IS:\t\t\t" . $geninfo->{"Organism"};
    push @output, "CHROMOSOME NUMBER IS:\t\t\t" . $geninfo->{"Chromosome"};

    push @output, "BASE-CALLING METHOD:\t\t\t" . "phred";
    push @output, "DATABASE USED:\t\t\t\t" . "consed";

    if ( exists $geninfo->{"CloneContiguousToggle"} && $geninfo->{"CloneContiguousToggle"} == 1 ) {
        push @output, "IS ENTIRE CLONE CONTIGUOUS:\t\t\tNO";
        processContigLines( $hash, \@output );
        push @output, "NAME OF THE FILE WHICH CONTAINS YOUR ENDS:\t\t"
        . $geninfo->{"FileContainingEnds"};
        push @output, "CONTIG CONTAINING THE LEFT END:\t\t\t"
        . $geninfo->{"ContigContainingLeftEnd"};
        push @output, "CONTIG CONTAINING THE RIGHT END:\t\t\t"
        . $geninfo->{"ContigContainingRightEnd"};
    }
    else {
        push @output, "IS ENTIRE CLONE CONTIGUOUS:\t\t\tYES";
        push @output,
        "WHICH CONTIG NUMBER WAS FINISHED:\t\t" . $geninfo->{"ContigNumber"};
        push @output,
        "THE ENTIRE CONTIG GOES FROM:\t\t"
        . $geninfo->{"EntireContigGoesFrom"} . " TO "
        . $geninfo->{"EntireContigGoesTo"};
        my $total =
        ( $geninfo->{"ContigFinishedTo"} ) -
        ( $geninfo->{"ContigFinishedFrom"} ) + 1;
        push @output,
        "THE CONTIG IS FINISHED FROM:\t\t"
        . $geninfo->{"ContigFinishedFrom"} . " TO "
        . $geninfo->{"ContigFinishedTo"}
        . " ($total bp)";

        push @output,
        "START CLONE SITE IS:\t\t\t"
        . $geninfo->{"StartCloneSite"} . " END "
        . $geninfo->{"EndCloneSite"};
    }

    push @output,
    "LEFT OVERLAPPING CLONE:\t\t\t"
    . ($geninfo->{"LeftOverlappingCloneName"} || ''). " "
    . ($geninfo->{"LeftOverlappingAccession"} || '');
    push @output,
    "LEFT OVERLAP ENDS AT:\t\t\t"
    . ($geninfo->{"LeftOverlapEndsAt"} || ''). " "
    . ($geninfo->{"LeftOverlapType"} || '');

    ## if changed from dace

    if ( $hash->{CLONE_DATA}->{NEIGHBOR_CHANGE}->{"Left"} ) {
        my $dace_change_reason = $geninfo->{"LeftNeighborChangeReason"};
        if ( $dace_change_reason eq "other" ) {
            $dace_change_reason = $geninfo->{"LeftOverlapChangeReasonOther"};
        }
        push @output,
        "LEFT NEIGHBOR REASON FOR CHANGE FROM DACE:\t" . $dace_change_reason;
    }

    push @output,
    "RIGHT OVERLAPPING CLONE:\t\t\t"
    . ($geninfo->{"RightOverlappingCloneName"} || ''). " "
    . ($geninfo->{"RightOverlappingAccession"} || '');
    push @output,
    "RIGHT OVERLAP BEGINS AT:\t\t\t"
    . ($geninfo->{"RightOverlapBeginsAt"} || ''). " "
    . ($geninfo->{"RightOverlapType"} || '');

    ## if changed from dace

    if ( $hash->{CLONE_DATA}->{NEIGHBOR_CHANGE}->{"Right"} ) {
        my $dace_change_reason = $geninfo->{"RightNeighborChangeReason"};
        if ( $dace_change_reason eq "other" ) {
            $dace_change_reason = $geninfo->{"RightOverlapChangeReasonOther"};
        }
        push @output,
        "RIGHT NEIGHBOR REASON FOR CHANGE FROM DACE:\t" . $dace_change_reason;
    }

    push @output, "WHICH PROGRAM WAS USED TO CONFIRM ASSEMBLY BY DIGEST?\t"
    . $geninfo->{"DigestAssemblyConfirmedByCombo"};

    if ( $geninfo->{"DigestCommentsToggle"} ) {
        push @output, "ANY COMMENTS REGARDING DIGEST?\t\t\tYES\n\t"
        . $geninfo->{"DigestCommentsText"};
    }
    else {
        push @output, "ANY COMMENTS REGARDING DIGEST?\t\t\tNO";
    }

    my $finaltext = "";
    foreach my $i ( 0 ... $#output ) {
        my $line_no = $i + 1;
        $finaltext .= $line_no . ") " . $output[$i] . "\n";
    }

    $finaltext .= processMiniLibComments($hash);
    $finaltext .= processTransposonComments($hash);
    $finaltext .= processPCROnlyRegions($hash);
    $finaltext .= processFragmentComments($hash);
    $finaltext .= processAmbiguousComments($hash);
    $finaltext .= processSingleCloneCoverageComments($hash);
    $finaltext .= processHomopolymericRunComments($hash);
    $finaltext .= processRepeatsComments($hash);
    $finaltext .= processPolymorphismComments($hash);
    $finaltext .= processOtherClonesComments($hash);
    $finaltext .= processAssemblyPiecesComments($hash);
    $finaltext .= processNonGenbankComments($hash);
    $finaltext .= processNonRepetitiveUnresolvedComments($hash);
    $finaltext .= processGSSAndOrMRNAOnlyDataComments($hash);
    $finaltext .= processAnyOtherComments($hash);
    $finaltext .= "\n\ngenerated by submit.rewrite\n";

    return $finaltext;
}

sub processContigLines {
    my ( $hash, $refOutput ) = @_;

    my @contigs = @{ $hash->{COMMENTS}->{"ContigData"} };

    my $numcontigs = 1 + $#contigs;
    push @{$refOutput},
    "NUMBER OF CONTIGS CONTAINING FINISHED SEQUENCE:\t" . $numcontigs;

    foreach my $i ( 0 ... $#contigs ) {
        push @{$refOutput},
        "CONTIG NUMBER OF "
        . textifyNumber( $i + 1 )
        . " CONTIG:\t\t"
        . $contigs[$i]->{"ContigNumber"};
        push @{$refOutput},
        "THE ENTIRE CONTIG GOES FROM:\t\t"
        . $contigs[$i]->{"EntireContigGoesFrom"} . " TO "
        . $contigs[$i]->{"EntireContigGoesTo"};
        my $total =
        ( $contigs[$i]->{"ContigFinishedTo"} ) -
        ( $contigs[$i]->{"ContigFinishedFrom"} ) + 1;
        push @{$refOutput},
        "THE CONTIG IS FINISHED FROM:\t\t"
        . $contigs[$i]->{"ContigFinishedFrom"} . " TO "
        . $contigs[$i]->{"ContigFinishedTo"}
        . " ($total bp)";

        push @{$refOutput},
        "START CLONING SITE:\t\t"
        . $contigs[$i]->{"StartCloneSite"} . " END "
        . $contigs[$i]->{"EndCloneSite"};
    }
}

sub processMiniLibComments
{
    my $hash = $_[0];

    my $output =
    "DOES CLONE CONTAIN MINI-LIBRARIES, TA CLONES OR TRANSPOSON BOMBING?\t\t";
    if ( verifyToggle( $hash, "MiniLibCommentsToggle" ) ) {
        $output .= "YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"MiniLibComments"} };
        foreach my $i (@mlc) {
            $output .= "\tDNA source:\t$i->{\"MiniLibCommentsDNASource\"}\n";
            $output .= "\tPlate name(s):\t$i->{\"MiniLibCommentsPlateName\"}\n";
            $output .=
            "\tContig number:\t$i->{\"MiniLibCommentsContigNumber\"}\n";
            $output .=
            "\tRegion is from:\t$i->{\"MiniLibCommentsRegionFrom\"} to: "
            . $i->{"MiniLibCommentsRegionTo"} . "\n";
            $output .=
            "\tCloneContains:\t$i->{\"MiniLibCommentsCloneContains\"}\n";

            if ( $i->{"MiniLibCommentsTextCommentToggle"} ) {
                $output .=
                "\tComments regarding Mini-Lib/TA Clones/Transposon Bombing:\n";
                $output .= $i->{"MiniLibCommentsTextComment"};
            }
        }
        $output .= "\n";
    }
    else {
        $output .= "NO\n";
    }

    return $output;
}

sub processTransposonComments {
    my $hash = $_[0];

    my $output = "DOES CLONE CONTAIN ANY TRANSPOSONS?\t\t\t";
    if ( verifyToggle( $hash, "TransposonCommentsToggle" ) ) {
        $output .= "YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"TransposonComments"} };
        foreach my $i (@mlc) {
            my $region = $i->{"TransposonCommentsSequenceRegion"};
            $output .= "\tSequence region transposon is inserted in: $region\n";
            $output .=
            "\tTransposon is in contig number: $i->{\"TransposonCommentsContigNumber\"}\n";

            if ( $region eq "Finished Region" ) {
                $output .="\tFirst Base of Transposon is at: "
                . $i->{"TransposonCommentsFirstBaseOfPosition"} . "\n";
                $output .="\tLast Base of Transposon is at: "
                . $i->{"TransposonCommentsLastBaseOfPosition"} . "\n\n";
            }
            $output .= "\n";

            if ( $i->{"TransposonCommentsTextCommentToggle"} ) {
                $output .= "\tComments regarding transposon:\n";
                $output .= $i->{"TransposonCommentsTextComment"} . "\n";
            }
        }
    }
    else {
        $output .= "NO\n";
    }

    return $output;
}

sub processPCROnlyRegions {
    my $hash = $_[0];

    my $output = "ANY REGIONS COVERED BY PCR ONLY?\t\t\t";
    if ( verifyToggle( $hash, "PCROnlyRegionsCommentsToggle" ) ) {
        $output .= "YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"PCROnlyRegionsComments"} };
        foreach my $i (@mlc) {
            $output .=
            "\tDNA source: " . $i->{"PCROnlyRegionsCommentsDNASource"} . "\n";
            $output .=
            "\tContig number: "
            . $i->{"PCROnlyRegionsCommentsContigNumber"} . "\n";
            $output .=
            "\tRegion is from: "
            . $i->{"PCROnlyRegionsCommentsRegionFrom"} . " to "
            . $i->{"PCROnlyRegionsCommentsRegionTo"} . "\n";
        }
        $output .= "\n";
    }
    else {
        $output .= "NO\n";
    }

    return $output;
}

sub processFragmentComments { "ANY REGIONS TO BE SUBMITTED AS FRAGMENTS?\t\tNO\n"; } # Not filled in anymore

sub processAmbiguousComments
{
    my $hash = $_[0];

    my $output = "ANY BASES TAGGED AMBIGUOUS/UNSURE?\t\t\t";
    if ( verifyToggle( $hash, "UnsureBasecallCommentsToggle" ) ) {
        $output .= "YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"UnsureBasecallComments"} };
        foreach my $i (@mlc) {
            $output .=
            "\tStart base position:\t$i->{\"UnsureBasecallCommentsStartBP\"}\n";
            $output .=
            "\tEnd base position:\t$i->{\"UnsureBasecallCommentsEndBP\"}\n";
            $output .= "\n";
        }
    }
    else {
        $output .= "NO\n";
    }

    return $output;
}

sub processSingleCloneCoverageComments
{
    my $hash = $_[0];

    my $output = "ANY REGIONS COVERED BY ONE SUBCLONE ONLY?\t\t";
    if ( verifyToggle( $hash, "SingleCloneCoverageCommentsToggle" ) ) {
        $output .= "YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"SingleCloneCoverageComments"} };
        foreach my $i (@mlc) {
            $output .=
            "\tStart base position:\t$i->{\"SingleCloneCoverageCommentsStartBP\"}\n";
            $output .=
            "\tEnd base position:\t$i->{\"SingleCloneCoverageCommentsEndBP\"}\n";
            $output .=
            "\tSubclone type:\t$i->{\"SingleCloneCoverageSubcloneType\"}\n";
            $output .= "\n";
        }
    }
    else {
        $output .= "NO\n";
    }

    return $output;
}

sub processOtherClonesComments {
    my $hash = $_[0];

    my $output = "ANY DATA FROM OTHER CLONES USED TO FINISH THIS CLONE?\t";
    if ( verifyToggle( $hash, "OtherClonesCommentsToggle" ) ) { $output .= "YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"OtherClonesComments"} };
        foreach my $i (@mlc) { $output .= "\tStart base position:\t".$i->{OtherClonesCommentsStartBP}."\n";
            $output .= "\tEnd base position:\t".$i->{OtherClonesCommentsEndBP}."\n";
            $output .= "\tContig number:\t\t".$i->{OtherClonesCommentsContigNumber}."\n";
            if ( exists $i->{OtherClonesCommentsStolenFromComment} ) {
                $output .= "\tStolen from:\t\t".$i->{OtherClonesCommentsStolenFromComment}."\n";
            }
            if ( exists $i->{OtherClonesCommentsDataTypeComment} ) {
                $output .= "\tData type:\t\t".$i->{OtherClonesCommentsDataTypeComment}."\n";
            }
            $output .= "\n";
        }
    }
    else { $output .= "NO\n";
    }
    return $output;
}

sub processHomopolymericRunComments
{
    my $hash = $_[0];

    my $output = "ANY UNRESOLVED HOMOPOLYMERIC RUNS?\t\t\t";
    if ( verifyToggle( $hash, "HomopolymericRunCommentsToggle" ) ) {
        $output .= "YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"HomopolymericRunComments"} };
        foreach my $i (@mlc) {
            $output .=
            "\tStart base position:\t$i->{\"HomopolymericRunCommentsStartBP\"}\n";
            $output .=
            "\tEnd base position:\t$i->{\"HomopolymericRunCommentsEndBP\"}\n";
            $output .= "\n";
        }
    }
    else {
        $output .= "NO\n";
    }

    return $output;
}

sub processRepeatsComments {
    my $hash = $_[0];

    my $output = "";

    my @types = (
        "UnresolvedTandemRepeats",     "UnresolvedDiTriRepeats",
        "UnresolvedLargeDuplications", "UnresolvedInvertedRepeats"
    );

    my %comment_checkbox_types = (
        "UnresolvedTandemRepeats" => ["DoesNotMeetFinishingStandardsCheckbox"],
        "UnresolvedLargeDuplications" =>
        [ "DiscrepanciesCheckbox", "DoesNotMeetFinishingStandardsCheckbox" ],
        "UnresolvedInvertedRepeats" => [
        "DiscrepanciesCheckbox", "DoesNotMeetFinishingStandardsCheckbox",
        "OrientationCheckbox"
        ],
        "UnresolvedDiTriRepeats" => ["DoesNotMeetFinishingStandardsCheckbox"]
    );

    my %checkboxes = (
        "DiscrepanciesCheckbox" =>
        "Discrepancies between repeat copies cannot be guaranteed as assembled",
        "OrientationCheckbox" =>
        "Orientation of loop sequence cannot be confirmed",
        "DoesNotMeetFinishingStandardsCheckbox" =>
        "Region does not meet required finishing standards"
    );

    my %typemapping = (
        "UnresolvedTandemRepeats" => "ANY UNRESOLVED TANDEM REPEATS?\t\t\t\t",
        "UnresolvedDiTriRepeats"  => "ANY UNRESOLVED SIMPLE-SEQUENCE REPEATS?\t\t\t",
        "UnresolvedLargeDuplications" => "ANY UNRESOLVED LARGE DUPLICATIONS?\t\t\t",
        "UnresolvedInvertedRepeats" => "ANY UNRESOLVED INVERTED REPEATS?\t\t\t",
    );

    foreach my $type (@types) {
        $output .= $typemapping{$type};

        if ( verifyToggle( $hash, $type . "CommentsToggle" ) ) {
            $output .= "YES\n";
            my @com        = @{ $hash->{COMMENTS}->{ $type . "Comments" } };
            my @checkboxes = @{ $comment_checkbox_types{$type} };
            foreach my $i (@com) {
                foreach my $box (@checkboxes) {
                    my $boxname = $type . "Comments" . $box;
                    if ( $i->{"$boxname"} )
                    {
                        $output .= "\t" . $checkboxes{$box} . "\n";
                    }
                }

                $output .=
                "\tSizing information:"
                . $i->{ $type . "CommentsSizingInfo" } . "\n";
                $output .=
                "\tStart base position: "
                . $i->{ $type . "CommentsStartBP" } . "\n";
                $output .=
                "\tEnd base position "
                . $i->{ $type . "CommentsEndBP" } . "\n";
                if ( $i->{ $type . "CommentsSizingInfo" } eq "Digest" ) {
                    $output .= "\tEnzyme: " . $i->{ $type . "Enzyme" } . "\n";
                    $output .= "\tReal: " . $i->{ $type . "Real" } . "\n";
                    $output .=
                    "\tIn silico: " . $i->{ $type . "InSilico" } . "\n";
                }
                elsif ( $i->{ $type . "CommentsSizingInfo" } eq "PCR" ) {
                    $output .=
                    "\tProduct size: " . $i->{ $type . "ProductSize" } . "\n";
                    $output .=
                    "\tAssembly size: "
                    . $i->{ $type . "AssemblySize" } . "\n";
                }
                elsif ( $i->{ $type . "CommentsSizingInfo" } eq "Subclone" ) {
                    $output .="\tSubclone: " . $i->{ $type . "SubClone" } . "\n";
                    $output .="\tIn silico: " . $i->{ $type . "InSilico" } . "\n";
                    $output .="\tLibrary size: " . $i->{ $type . "LibrarySize" } . "\n";
                }

                $output .= "\n\n";
            }
        }
        else { $output .= "NO\n"; }
    }

    return $output;
}

sub processPolymorphismComments { "WERE POLYMORPHISMS IDENTIFIED?\t\t\t\tNO\n" } # Not filled in anymore

sub processAssemblyPiecesComments {
    my $hash = $_[0];

    my $output = "ARE THERE ANY ASSEMBLY PIECES IN THIS CLONE?\t\t";
    if ( verifyToggle( $hash, "AssemblyPiecesCommentsToggle" ) ) {
        $output .= "YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"AssemblyPiecesComments"} };
        foreach my $i (@mlc)
        {
            $output .=
            "\tStart base postion:\t$i->{\"AssemblyPiecesCommentsStartBP\"}\n";
            $output .=
            "\tEnd base position:\t$i->{\"AssemblyPiecesCommentsEndBP\"}\n";
            $output .= "\n";
        }
    }
    else {
        $output .= "NO\n";
    }
    return $output;
}

sub processNonGenbankComments {
    my $hash = $_[0];

    my $output = "ANY NON-GENBANK COORDINATOR-APPROVED AREAS?\t\t";
    if ( verifyToggle( $hash, "NonGenbankCommentsToggle" ) ) {
        $output .= "YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"NonGenbankComments"} };
        foreach my $i (@mlc)
        {
            $output .=
            "\tStart base postion:\t$i->{\"NonGenbankCommentsStartBP\"}\n";
            $output .=
            "\tEnd base position:\t$i->{\"NonGenbankCommentsEndBP\"}\n";
            $output .=
            "\tCoordinator(s) approving:\t$i->{\"NonGenbankCommentsCoordinators\"}\n";
            $output .= "\n";
        }
    }
    else {
        $output .= "NO\n";
    }
    return $output;
}

sub processNonRepetitiveUnresolvedComments {
    my $hash = $_[0];

    my $output = "ANY NON-REPETITIVE BUT UNRESVOLED AREAS?\t\t";

    if ( verifyToggle ($hash, "NonRepetitiveButUnresolvedRegionCommentsToggle") ) {
        $output .="YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"NonRepetitiveButUnresolvedRegionComments"} };
        foreach my $i (@mlc) {
            $output .= "\tStart base postion:\t$i->{\"NonRepetitiveButUnresolvedRegionCommentsStartBP\"}\n";
            $output .= "\tEnd base position:\t$i->{\"NonRepetitiveButUnresolvedRegionCommentsEndBP\"}\n";
            $output .= "\n";
        }
    }
    else {
        $output .= "NO\n";
    }

    return $output;
}

sub processGSSAndOrMRNAOnlyDataComments {
    my $hash = $_[0];

    my $output = "ANY GSS AND OR mRNA ONLY DATA?\t\t\t\t";

    if ( verifyToggle ($hash, "GSSAndOrMRNAOnlyDataCommentsToggle") ) {
        $output .="YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"GSSAndOrMRNAOnlyDataComments"} };
        foreach my $i (@mlc) {
            $output .= "\tStart base postion:\t$i->{\"GSSAndOrMRNAOnlyDataCommentsStartBP\"}\n";
            $output .= "\tEnd base position:\t$i->{\"GSSAndOrMRNAOnlyDataCommentsEndBP\"}\n";
            $output .= "\n";
        }
    }
    else {
        $output .= "NO\n";
    }

    return $output;
}

sub processAnyOtherComments {
    my $hash = $_[0];

    my $output = "ANY OTHER COMMENTS REGARDING THIS CLONE?\t\t";
    if ( verifyToggle( $hash, "AnyOtherCommentsToggle" ) ) {
        $output .= "YES\n";
        my @mlc = @{ $hash->{COMMENTS}->{"AnyOtherComments"} };
        foreach my $i (@mlc) {
            $output .= $i->{"AnyOtherCommentsText"};
            $output .= "\n";
        }
    }
    else {
        $output .= "NO\n";
    }
    return $output;
}

sub verifyToggle {
    my ( $hash, $key ) = @_;

    my @toggles = @{ $hash->{TOGGLES} };
    foreach my $i (@toggles) {
        if ( $i eq $key ) {
            return 1;
        }
    }
    return 0;
}

sub textifyNumber {
    my $num     = $_[0];
    my %NUM_MAP = (
        1  => "FIRST",
        2  => "SECOND",
        3  => "THIRD",
        4  => "FOURTH",
        5  => "FIFTH",
        6  => "SIXTH",
        7  => "SEVENTH",
        8  => "EIGHTH",
        9  => "NINTH",
        10 => "TENTH",
        11 => "ELEVENTH",
        12 => "TWELTH",
        13 => "THIRTEENTH",
        14 => "FOURTEENTH",
        15 => "FIFTEENTH"
    );

    return $NUM_MAP{$num};

}

sub textifyNameList {
    my ( $hash, $source_key, $dest_key ) = @_;
    my $list_expanded = "";

    my @list_deref = ();

    if ( exists( $hash->{"$source_key"} ) ) {
        if ( ref( $hash->{"$source_key"} ) eq 'ARRAY' ) {
            push @list_deref, @{ $hash->{"$source_key"} };
        }
    }

    foreach my $i ( 0 .. $#list_deref ) {
        $list_expanded .= $list_deref[$i];
        $list_expanded .= " & " if ( $i != $#list_deref );
    }

    $hash->{"$dest_key"} = $list_expanded;
}

1;

