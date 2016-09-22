package RefImp::Project::Command::Notes;

use strict;
use warnings 'FATAL';

class RefImp::Project::Command::Notes {
    is => 'RefImp::Project::Command::Base',
    has => {
        #prefinisher => { is => 'Text', doc => 'prefinisher to add to claim project and add to notes', },
    },
};

sub execute {
    my $self = shift;

    #FIXME $name = prefinisher

    my $project = $self->project;
    my $clone = RefImp::Clone->get(name => $project->name);
    $self->warning_message('Failed to find clone for %s', $project->name) if not $clone;

    # Chromosome
    my $chromosome = ( $clone ? $clone->chromosome : 'unknown' );

    my $date = `date +%D`;
    my $timestamp = `date +%Y%m%d`;
    chomp $timestamp;

    my $phredinfo = `grep "phred20 coverage from contigs" ./edit_dir/status`;
    my @phredarray = split(":",$phredinfo); 

    $phredinfo2 = `grep "Total size of contigs greater than 1 kb" ./edit_dir/status`;

    $phredinfo3 = `grep "Estimated size of clone from library core" ./edit_dir/status`;

    system ("sumfindid.test");

    my ($clone_prefix) = $clone =~ /^(.{2})/;

#check to see if its been run before#
#info from original notes file
    my $notesfile = $project->notes_file_path;
    unless (-e $notesfile){system(`touch $notesfile`)}
    open(NOTES, "<$notesfile") or die "can't open notes file!\n";
    my @notes = <NOTES>;
    close(NOTES);

#moving the original notes file to *notes.old
    system ("/bin/mv $notesfile $notesfile.old.$timestamp") == 0 or die "Problem backing-up notes file!\n";

#get TPF info
    my @TPFoutputI = ();
    if ($clone =~ /^Z_/)
    {
        @TPFoutputI = `GetTilepath -clone $clone -depth 6`;
    }
    else
    {
        @TPFoutputI = `GetTilepath -clone $clone`;
    }

    open(TNOUT, ">TransposonHits.out");
##Pal run for TPF file info
    my $overlapsdir = ($directory .'/edit_dir/overlaps');
    chdir $overlapsdir;
    system ("makecon -whole $clone"); 

    my @neighbor_list;
    my %TPFhash;
    foreach $sline (@TPFoutputI){
        next if ($sline=~/^(OVERLAP|------)/);
        my @elements = split(/\s+/, $sline);
        if (($elements[1] eq "") || ($elements[1] eq $clone)){
        }else{
            if (($elements[6] eq "WUGSC") || (-e "/gscuser/seqmgr/$clone")){
                $IHclone = $elements[1];
                push(@neighbor_list, $IHclone);
                $TPFhash{$IHclone}=1;
                system ("makecon $IHclone");
                system ("pal -s 300 -files $clone.con $IHclone.con -out $clone.$IHclone.pal300 2> $clone.$IHclone.pal300.positions");
            }
            else{                #if its anything but WUGSC use accession and get con from that ACC dir, but try an in house first
                #		@multiacc = split(/\s/, $elements[2]);
                my $ACCclone = $elements[2];
                $IHname = $elements[1];
                if (($IHname ne "-") && (-d "/gscuser/seqmgr/$IHname")){
                    push(@neighbor_list, $IHname);
                    $TPFhash{$IHname}=1;
                    system ("makecon -whole $IHname");
                    system ("pal -s 300 -files $clone.con $IHname.con -out $clone.$IHname.pal300 2> $clone.$IHname.pal300.positions");
                }else{
                    unless ($ACCclone =~ /\-/){
                        system ("cp /home1/watson/accmgr/$ACCclone/edit_dir/$ACCclone $ACCclone.con");
                        system ("pal -s 300 -files $clone.con $ACCclone.con -out $clone.$ACCclone.pal300 2> $clone.$ACCclone.pal300.positions");
                    }
                }
            }
        }
#    }
    }

#$transposonhits = `grep Contig /home1/watson/seqmgr/$clone/sumfindid.out`;
    open(SMFID, "</gscuser/seqmgr/$clone/sumfindid.out.test");
    @transposonhits = grep(/^Contig\d/, <SMFID>);
    close(SMFID);
    open(SMFID2, "</gscuser/seqmgr/$clone/sumfindid.out.test");
    @alerthits = grep(/^\s+(\d+|IS|TN)/, <SMFID2>);
    close(SMFID2);

    my %TNhash;
    my %TNhash2;

    foreach $TNhitline (@transposonhits){
        chomp $TNhitline;
        $TNhitline =~ s/^\s+//g;
        @foo = split(/\s+/, $TNhitline);
        $TNhash{$TNhitline}{'contig'} = $foo[0];
        $TNhash{$TNhitline}{'score'} = $foo[2];
        $TNhash{$TNhitline}{'line'} = $TNhitline;
    }
    $sort0 = 'contig';
    $sort1 = 'score';
    $sort2 = 'line';
    my @TNreturn = ();
    foreach $KEY (sort {$TNhash{$a}{$sort0} cmp $TNhash{$b}{$sort0}
                or $TNhash{$b}{$sort1} <=> $TNhash{$a}{$sort1}
                or $TNhash{$a}{$sort2} cmp $TNhash{$b}{$sort2}
        }
        keys %TNhash)

    {    
        $stack = $TNhash{$KEY}{'contig'};
        $TNhash2{$stack} = $TNhash{$KEY}{'line'};
    }
    foreach $KEY (sort {$TNhash2{$a} cmp $TNhash2{$b}} keys %TNhash2)
    {
        push (@TNreturn, "$TNhash2{$KEY}\n");
    }


    @sumFindidout = ( );

#print TNOUT "TRANSPOSON HITS TO $clone\n\n";
    my $sumFind = `grep $clone_prefix /gscuser/seqmgr/$clone/sumfindid.out.test`;
    my @sumF = split(/\n/, $sumFind);
    foreach $lineF (@sumF){
        chomp ($lineF);
        $lineF =~ s/^\s+//g;
        @sumla = split(/\s+/, $lineF);

        unless ($lineF =~ /$clone/){
            $contighit = $sumla[2];
            $hitstart = $sumla[4];
            $hitfin = $sumla[5];
            $hitavg = (($hitstart + $hitfin) / 2);
            $transposonhit = 0;

            foreach $hitline (@transposonhits){
                @tn = split(/\s+/, $hitline);
                if ($tn[4] < $tn[5]){$tnhit1 = $tn[4]; $tnhit2 = $tn[5]}
                if ($tn[4] > $tn[5]){$tnhit1 = $tn[5]; $tnhit2 = $tn[4]}
                if (($tn[0] =~ /$contighit/) && 
                    (
                        (($tnhit1 <= $hitstart) && ($hitstart <= $tnhit2)) ||
                        (($tnhit1 <= $hitfin) && ($hitfin <= $tnhit2)) ||
                        (($tnhit1 <= $hitavg) && ($hitavg <= $tnhit2))
                    )
                ){$transposonhit = 1}
            }
        }
        if ($sumla[0] =~ /$clone/){
            push(@sumFindidout, "$sumla[0]\n");
        }
        elsif (($sumla[0] =~ /$clone_prefix/) && ($sumla[0] !~ /$clone/)){
            if ($transposonhit =~ /1/){
                print TNOUT "-- $sumla[0] --Transposon\n";
            }else{
                push(@neighbor_list, $sumla[0]);
                unless ((-e "$clone.$sumla[0].pal300") && ((-M "$clone.$sumla[0].pal300") < 1)){
                    system ("makecon -whole $sumla[0]");
                    system ("pal -s 300 -files $clone.con $sumla[0].con -out $clone.$sumla[0].pal300 2> $clone.$sumla[0].pal300.positions");
                }
                push(@sumFindidout, "$sumla[0]\n");
            }
        }

    }
    close(TNOUT);
#get coverage status for each clone in neighbor_list
    my %hash;
    $hash{$_} = 1 for (@neighbor_list);
    my @uniqueN = ();
    push @uniqueN, $_ for (keys %hash);

    my %hash2;
    $hash2{$_} = 1 for (@sumFindidout);
    my @uniqueS = ();
    push @uniqueS, $_ for (keys %hash2);

#Feiyu add project_status here
    chomp @uniqueN;
    my $tempfile="/tmp/pfnotes.$$";
    open (OUT, ">$tempfile") or die "Can't write to $tempfile\n";
    map {print OUT $_."\n"} @uniqueN;
    close OUT;
    my @checkstat=`project_status -fof $tempfile`;
    my %clonestat;
    foreach (@checkstat) {
        next if (/^(Project|--------)/);
        my ($proname,$prostat)=$_=~/^(\S+)\s+\S+\s+\S+\s+(\S+)/;
        $clonestat{$proname}=$prostat;
    }
    unlink $tempfile;

    @coverage = "\n";
#@coverage = "VERIFIED NEIGHBOR SHOTGUN STATUS:\n";
    foreach $neighbor (@uniqueN){
        #chomp $neighbor;
        if (-e "/gscuser/seqmgr/$neighbor/edit_dir/status"){
            $statcheck = `grep "Number of reads in contigs of 1 read or more   :" /gscuser/seqmgr/$neighbor/edit_dir/status`;
            chomp $statcheck;
            $statcheck = reverse $statcheck;
            @stats = split(/\s+/, $statcheck);
            $statsN = reverse $stats[0];
            chomp $statsN;
            $statsN = "NA" unless ($statsN =~ /^\d+$/);
        }else{
            $statsN = ($neighbor =~/Transposon/) ? "TRANS" : $clonestat{$neighbor}; 
        }
        unless (($statsN eq "NA") || ($statsN eq "TRANS")){
            if (($statsN > 0) && (-e "/gscuser/seqmgr/$clone/edit_dir/overlaps/$clone.$neighbor.pal300")){
                push(@coverage, "$clone.$neighbor.pal300 $statsN reads $date");
            }else{
                my $words = ($statsN > 0) ? "$statsN reads" : $statsN;
                push(@coverage, "$clone.$neighbor $words $date");
            }
        }
        push (@coverage, "-- $neighbor\n") if ($statsN eq "TRANS");
    }

    @sortsumFindidout = sort { $a cmp $b } @uniqueS;
    my @TPFcoverage=();
    my @othercoverage=();
    foreach my $cover (@coverage) {
        my $flag;
        foreach my $key (keys %TPFhash) {
            if ($cover=~/$key/) {
                push(@TPFcoverage,$cover);
                $flag++;
                last;
            }else{
                next;
            }
        }
        push(@othercoverage,$cover) unless ($flag);
    }

    unless (-z  "/gscuser/seqmgr/$clone/TransposonHits.out"){$findfile = "see $clone/TransposonHits.out for transposon hits\n"}
    else{$findfile = "\n"}

    my @header = "\n";
    push(@header, "CLONE= $clone\n");
    push(@header, "CHROMOSOME= $chromosome\n");
    push(@header, "SORTER= $name\n");
    push(@header, "FINISHER=\n");
    push(@header, "~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~\n");

    my @moreinfo = "\n";
    push(@moreinfo, "============================================\n");
    push(@moreinfo, "\n");
    push(@moreinfo, "PREFINISH INITIATED ON $date");
    push(@moreinfo, "\n");
    push(@moreinfo, "PHRED20 COVERAGE FROM CONTIGS: $phredarray[1]");
    push(@moreinfo, "\n");
    push(@moreinfo, uc"$phredinfo2\n");
    push(@moreinfo, uc"$phredinfo3\n");
    push(@moreinfo, "\n");
    push(@moreinfo, "SIGNIFICANT FINDID HITS: $findfile");
    push(@moreinfo, "@sortsumFindidout\n");
    push(@moreinfo, "TRANSPOSON:\n");
    if (defined @transposonhits){
        push(@moreinfo, "contig  size    score   %       hit\n");
        push(@moreinfo, "=========================================================\n");
        push(@moreinfo, "@TNreturn\n");
    }
    if (defined @alerthits){
        foreach (@alerthits){push(@moreinfo, $_)}
    }

    push(@moreinfo, "\n");
    push(@moreinfo, "============================================\n");

    my @lastbit = "\n";
    push(@lastbit, "RAIDED DATA:\n");
    push(@lastbit, "      Clone:\n");
    push(@lastbit, "     Status:\n");
    push(@lastbit, "       Raid:\n");
    push(@lastbit, "\n");
    push(@lastbit, "PCR ATTEMPTED:\n");
    push(@lastbit, "\n");
    push(@lastbit, "DIGEST OK?\n");
    push(@lastbit, "\n");
    push(@lastbit, "CLONE STATUS:\n");
    push(@lastbit, "       #Ctgs:\n");
    push(@lastbit, "    #Spanned:\n");
    push(@lastbit, "\n");
    push(@lastbit, "KB TO FINISH:\n");
    push(@lastbit, "\n");
    push(@lastbit, "NOTES TO FINISHER:\n");
    push(@lastbit, "\n");
    push(@lastbit, "~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~\n");
    push(@lastbit, "\n");


#to output -> write brand new Notes file
    chdir $directory;
    open(OUTPUT, ">$notesfile") or die "$!\n";

    print OUTPUT "@header\n";
    print OUTPUT "@notes\n";
    print OUTPUT "@moreinfo\n";
    print OUTPUT "TPF INFORMATION:\n";
    print OUTPUT " @TPFoutputI\n";
    print OUTPUT "\n";
    print OUTPUT "PALS ASSESSMENT: \n";
    print OUTPUT " @TPFcoverage@othercoverage\n";
    print OUTPUT "\n";
    print OUTPUT "============================================\n";
    print OUTPUT "\n";
    print OUTPUT "@lastbit\n";
    close(OUTPUT);

    return 1;
}

1;

