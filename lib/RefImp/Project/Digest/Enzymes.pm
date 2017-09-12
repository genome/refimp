package Refimp::Project::Digest::Enzymes;

use strict;
use warnings;

use List::MoreUtils 'firstidx';
use Params::Validate qw/ :types validate_pos /;

my %codes_and_enzymes = (
    af => "AfeI",
    ao => "AfoI",
    ap => "ApaI",
    av => "AvrII",
    bg => "BglI",
    bp => "BspEI",
    bs => "BstXI",
    bi => "BspHI",
    ha => "HpaI",
    hp => "HindIII PstI",
    ms => "MscI",
    pp => "PpiMI",
    pv => "PvuII",
    sa => "SacI",
    sc => "ScaI",
    sl => "SalI",
    sk => "SacII",
    sp => "SphI",
    st => "StuI",
    tt => "TthlllI",
    xb => "XbaI",
    xm => "XmaI",
    bl => "BglII",
    eh => "EcorV HindIII",
    rs => "EcorI SacI",
    xn => "XmnI",
    ni => "NotI",
    as => "Ase I",
    aa => "Ava I",
    bz => "Bsp1720 I",
    se => "Spe I",
    dr => "Dra I",
    na => "Nae I",
    ng => "NgoMIV",
    b => "BamHI",
    c => "ClaI",
    d => "DraIII",
    e => "EcoRV",
    h => "HindIII",
    k => "KpnI",
    m => "MspAlI",
    n => "HincII",
    p => "PstI",
    r => "EcoRI",
    s => "SmaI",
    t => "BstEII",
    x => "XhoI",
);
sub enzyme_for_code {
    my ($self, $code) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});
    return $codes_and_enzymes{$code} if exists $codes_and_enzymes{$code};
    return;
}

1;

