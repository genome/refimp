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
    reads => 'Tenx::Reads::Command',
    reference => 'Tenx::Reference::Command',
);
$Tenx::Command::SUB_COMMAND_MAPPING = \%command_map;

1;
