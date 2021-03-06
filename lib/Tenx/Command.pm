package Tenx::Command;

use strict;
use warnings;

class Tenx::Command {
    is => 'Command::Tree',
    doc => '10X Genomics commands and utilites',
};

# set commands and classes instead of using the directory structure
my %command_map = (
    alignment => 'Tenx::Alignment::Command',
    assembly => 'Tenx::Assembly::Command',
    reads => 'Tenx::Reads::Command',
    refseq => 'Tenx::Refseq::Command',
    util => 'Tenx::Util::Command',
);
$Tenx::Command::SUB_COMMAND_MAPPING = \%command_map;

1;
