package RefImp::Project::Command::Digest;

use strict;
use warnings;

use Params::Validate qw/ :types validate_pos /;

class RefImp::Project::Command::Digest {
    is => 'Command::Tree',
    doc => 'work with projects digests',
};

sub enzyme_for_code {
    my ($self, $clone_enzyme) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    my $szEnzymeName;
    if( $clone_enzyme =~ /af$/ ) {
        $szEnzymeName = "AfeI";
    }elsif( $clone_enzyme =~ /ao$/ ) {
        $szEnzymeName = "AfoI";
    }elsif( $clone_enzyme =~ /ap$/ ) {
        $szEnzymeName = "ApaI";
    }elsif( $clone_enzyme =~ /av$/ ) {
        $szEnzymeName = "AvrII";
    }elsif( $clone_enzyme =~ /bg$/ ) {
        $szEnzymeName = "BglI";
    }elsif( $clone_enzyme =~ /bp$/ ) {
        $szEnzymeName = "BspEI";
    }elsif( $clone_enzyme =~ /bs$/ ) {
        $szEnzymeName = "BstXI";
    }elsif( $clone_enzyme =~ /bi$/ ) {
        $szEnzymeName = "BspHI";
    }elsif( $clone_enzyme =~ /ha$/ ) {
        $szEnzymeName = "HpaI";
    }elsif( $clone_enzyme =~ /hp$/ ) {
        $szEnzymeName = "HindIII PstI";
    }elsif( $clone_enzyme =~ /ms$/ ) {
        $szEnzymeName = "MscI";
    }elsif( $clone_enzyme =~ /pp$/ ) {
        $szEnzymeName = "PpiMI";
    }elsif( $clone_enzyme =~ /pv$/ ) {
        $szEnzymeName = "PvuII";
    }elsif( $clone_enzyme =~ /sa$/){
        $szEnzymeName = "SacI";
    }elsif( $clone_enzyme =~ /sc$/ ) {
        $szEnzymeName = "ScaI";
    }elsif( $clone_enzyme =~ /sl$/ ) {
        $szEnzymeName = "SalI";
    }elsif( $clone_enzyme =~ /sk$/ ) {
        $szEnzymeName = "SacII";
    }elsif( $clone_enzyme =~ /sp$/ ) {
        $szEnzymeName = "SphI";
    }elsif( $clone_enzyme =~ /st$/ ) {
        $szEnzymeName = "StuI";
    }elsif( $clone_enzyme =~ /tt$/ ) {
        $szEnzymeName = "TthlllI";
    }elsif( $clone_enzyme =~ /xb$/ ) {
        $szEnzymeName = "XbaI";
    }elsif( $clone_enzyme =~ /xm$/ ) {
        $szEnzymeName = "XmaI";
    }elsif( $clone_enzyme =~ /bl$/) {
        $szEnzymeName = "BglII";
    }elsif( $clone_enzyme =~ /eh$/ ) {
        $szEnzymeName = "EcorV HindIII";
    }elsif( $clone_enzyme =~ /rs$/ ) {
        $szEnzymeName = "EcorI SacI";
    }elsif( $clone_enzyme =~ /xn$/ ) {
        $szEnzymeName = "XmnI";
    }elsif ($clone_enzyme =~ /ni$/ ) {
        $szEnzymeName = "NotI";
    }elsif ($clone_enzyme =~ /as$/ ) {
        $szEnzymeName = "Ase I";
    }elsif ($clone_enzyme =~ /aa$/ ) {
        $szEnzymeName = "Ava I";
    }elsif ($clone_enzyme =~ /bz$/ ) {
        $szEnzymeName = "Bsp1720 I";
    }elsif ($clone_enzyme =~ /se$/ ) {
        $szEnzymeName = "Spe I";
    }elsif ($clone_enzyme =~ /dr$/ ) {
        $szEnzymeName = "Dra I";
    }elsif ($clone_enzyme =~ /na$/ ) {
        $szEnzymeName = "Nae I";
    }elsif ($clone_enzyme =~ /ng$/ ) {
        $szEnzymeName = "NgoMIV";

    }elsif( $clone_enzyme =~ /b$/) {
        $szEnzymeName = "BamHI";
    }elsif( $clone_enzyme =~ /c$/) {
        $szEnzymeName = "ClaI";
    }elsif( $clone_enzyme =~ /d$/) {
        $szEnzymeName = "DraIII";
    }elsif( $clone_enzyme =~ /e$/){
        $szEnzymeName = "EcoRV";
    }elsif( $clone_enzyme =~ /h$/){
        $szEnzymeName = "HindIII";
    }elsif( $clone_enzyme =~ /k$/) {
        $szEnzymeName = "KpnI";
    }elsif( $clone_enzyme =~ /m$/) {
        $szEnzymeName = "MspAlI";
    }elsif( $clone_enzyme =~ /n$/) {
        $szEnzymeName = "HincII";
    }elsif( $clone_enzyme =~ /p$/) {
        $szEnzymeName = "PstI";
    }elsif( $clone_enzyme =~ /r$/){
        $szEnzymeName = "EcoRI";
    }elsif( $clone_enzyme =~ /s$/) {
        $szEnzymeName = "SmaI";
    }elsif( $clone_enzyme =~ /t$/) {
        $szEnzymeName = "BstEII";
    }elsif( $clone_enzyme =~ /x$/) {
        $szEnzymeName = "XhoI";
    }else {
        die "do not recognize enzyme code $clone_enzyme in $_";
    }
    return $szEnzymeName;
}

1;

