package Pacbio::Command;

use strict;
use warnings 'FATAL';

class Pacbio::Command {
    is => 'Command::Tree',
    doc => 'work with pacbio technologies',
};

# Use command map until when/if UR PR #152 gets merged with the quotemeta fix
my %command_map = (
    assembly => 'Pacbio::Command::Assembly',
    run => 'Pacbio::Run::Command',
);
$Pacbio::Command::SUB_COMMAND_MAPPING = \%command_map;
1;
