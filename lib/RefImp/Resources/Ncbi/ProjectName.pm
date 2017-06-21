package RefImp::Resources::Ncbi::ProjectName;

use strict;
use warnings 'FATAL';

use Params::Validate qw/ :types validate_pos /;

my %local_to_ncbi_prefix = (
    # human
    H_GS => 'GS1',
    H_RG => {
        CTB => { min => 1, max => 194},
        CTA => { min => 195 },
    },
    H_GD => 'CH17',
    H_FS => 'CH14',
    H_FT => 'CH15', 
    H_FU => 'CH16', 
    H_FH => { RP13 => { min => 1, max => 1056, }, },
    H_GT => 'CA', 
    H_DJ => { 
        RP1 => { min => 1, max => 321 },   
        RP3 => { min => 322, max => 528 }, 
        RP4 => { min => 529, max => 816  },
        RP5 => { min => 817, max => 1200 },
    },
    H_DA => 'RP6', 
    H_NH => 'RP11',
    H_MS => { 
        CTB => { min => 1, max => 194  },
        CTC => { min => 195, max => 879 },
        CTD => { min => 2001, max => 2423 },
    },
    H_TD => { CTD => { min => 2501, max => 3254 }, },
    H_BK => { CTA => { min => 1, max => 1000 }, },
    H_N => 'LLcos', 
    H_U => 'LLcos', 
    H_LL => 'LLcos', 
    H_LUCA => 'LLcos', 
    H_AA => 'WI2',
    H_GR => 'ABC7',
    H_IB => 'ABC8',
    H_GJ => 'ABC9',
    H_GK => 'ABC10',
    H_GL => 'ABC12',
    H_GZ => 'ABC13',
    H_HA => 'ABC14',
    H_HS => 'ABC16',
    H_IK => 'ABC17',
    H_HD => 'ABC18',
    H_HE => 'ABC19',
    H_HQ => 'ABC20',
    H_HK => 'ABC21',
    H_HJ => 'ABC22',
    H_HP => 'ABC23',
    H_HN => 'ABC24',
    H_IO => 'ABC26',
    H_HO => 'ABC27',
    H_HS => 'ABC16',
    # mouse
    M_BA => 'RP23',
    M_BB => 'RP24',
    M_AA => 'CH25',
    M_AE => 'CH36',
    M_AN => 'WI1',
    # mouse bac
    MDAA => 'CH26',
    MEAA => 'CH33',
    MFAA => 'CH35',
    #cat
    FCAB => 'FCAB',
    # chimp
    C_PT => 'RP43',
    C_AB => { CH251 => { min => 1, max => 576 }, },
    C_AC => 'CH1251',
    C_AD => { CH251 => { min => 577 }, },
    # dog
    D_CF => 'RP81',
    # baboon
    AAAA => 'RP41',
    # chicken
    J_AA => 'CH261', 
    J_AC => 'CH1261',
    JB => 'TAM31',
    JE => 'TAM32',
    JH => 'TAM33',
    J_AD => 'J_AD',
    J_AE => 'J_AE',
    # marmoset 
    CXAP => 'MARM',
    # macaque
    MQAB => { CH250 => { min => 1, max => 288 }, },
    MQAC => { CH250 => { min => 289, max => 576 }, },
    MQAF => 'RMAEX',
    # soybean
    GMAC => 'GMW2',
    # platypus
    KAAH => 'CH236',
    KAAB => 'OABb',
    # opossum
    MDAP => 'VMRC6',
    MDAR => 'MDAEX',
    # orangutan
    PPAD => 'CH1276', # fosmid
    PPAE => 'CH276', # BAC
    # lamprey
    PMAJ => 'CH303',
    PMAY => 'VMRC47',
    # snail 
    BGAD => 'BG_BBa',
    #tree shrew
    TIAB => 'CH275',
    # xenopus tropicalis
    OAAA => { CH216 => { min => 1, max => 171 }, },
    OAAB => { ISB1 => { min => 1, max => 199 }, },
    OAAC => { ISB1 => { min => 201, max => 400 }, },
    OAAD => { CH216 => { min => 181, max => 432 }, },
    # maize
    Z_AI => 'Z_AI',
    Z_AF => { CH201 => { min => 1,   max => 288 }, },
    Z_AG => { CH201 => { min => 289, max => 576 }, },
    Z_AH => 'ZMMBBb',
    # Trichinella BAC end sequences
    TPAC => 'TS195',
    TPAE => 'TS195',
    # Gibbons
    NLAA => 'CH271',
    # marmoset
    CXAH => 'CH259',
    # Zebra Finch
    TGAC => 'TGMCBa',
    TGAA => 'TG_Ba',
    # Oxytricha 20kb Linear Mitochondrial projects from Tom Doak
    OXAP => 'OXAP',
    OXAT => 'OXAT',
    OXAV => 'OXAV',
    OXAW => 'OXAW',
    # Priapulus caudatus BAC Library
    PCBA => 'PCCBA',
    # anopheles
    ALAS => 'AGMCBa',
    # Anaerostipes caccae
    ANAA => 'ANAA',
    # Cyanothece
    AFAA => 'AFAA',
    AFAB => 'AFAB',
    # Platyfish
    XMAA => 'WLC1247',
    #Heterorhabditis bacteriophora
    HTAP => 'HHB',
    # bull
    BTBB => 'CH240',
    BTBA => 'BTDAEX',
    # gorilla
    FAAB => 'CH277',
    FAAC => 'CH255',
    # shark
    CMBC => 'IMCB_Eshark',
    # turtle
    CPBM => 'CHY3',
    # sandfly BES
    PRAK => 'PLPAAEX',
    # Rhodnius prolixus
    NADN => 'RPAEX',
    # c japonica
    CJAJ => 'CJAJ',
    # vervet
    CASB => 'CH252',
);
sub get {
    my ($class, $project_name) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    # Parsre name. If not parsable, return project name
    my ($prefix, $plate, $row, $col) = $class->parse_project_name($project_name);
    return $project_name if not $prefix;

    # No known prefix to substitute
    my $conversion = $local_to_ncbi_prefix{$prefix};
    return $project_name if not $conversion;

    # Remove leading zeros from plate and col
    $plate =~ s/^0+//;
    $col =~ s/^0+//;

    # Just a straight conversion
    if ( not ref $conversion ) {
        return join('-', $conversion, join('', $plate, $row, $col));
    }

    # The conversion depends on the plate number in a range
    foreach my $new_prefix ( keys %$conversion ) {
        next if $plate < $conversion->{$new_prefix}->{min};
        next if exists $conversion->{$new_prefix}->{max} && $plate > $conversion->{$new_prefix}->{max};
        return join('-', $new_prefix, join('', $plate, $row, $col));
    }

    # Plate was not in the range of substitutions
    return $project_name;
}

sub ncbi_to_local {
    my ($class, $project_name) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    # Parse name. If not parsable, return project name
    my ($prefix, $plate, $row, $col) = $class->parse_project_name($project_name);
    return $project_name if not $prefix;

    # Add 0 back to col - how to add back to plate??
    $col = sprintf('%02d', $col);

    for my $local_prefix ( keys %local_to_ncbi_prefix ) {
        my $conversion = $local_to_ncbi_prefix{$local_prefix};
        if ( ref $conversion ) {
            foreach my $new_prefix ( keys %$conversion ) {
                next if $prefix ne $new_prefix;
                next if $plate < $conversion->{$new_prefix}->{min};
                next if exists $conversion->{$new_prefix}->{max} && $plate > $conversion->{$new_prefix}->{max};
                return join('-', $local_prefix, join('', $plate, $row, $col));
            }
        }
        else {
            if ( $prefix eq $conversion ) {
                return join('-', $local_prefix, join('', $plate, $row, $col));
            }
        }
    }

    return $project_name;
}

sub parse_project_name {
    my ($class, $project_name) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});
    
    return unless $project_name =~ m/^([[:upper:]]\w*)-(\w+)([[:upper:]])(\d+)$/x;

    my $prefix = $1;
    my $plate = $2;
    my $row = $3;
    my $col = $4;

    return ($prefix, $plate, $row, $col);
}

1;
