package Sx::Command;

use strict;
use warnings 'FATAL';

class Sx::Command {
    is => 'Command::Tree',
    doc => 'Transform sequences with ease',
};

# This map allows the top-level commands to be set
# instead of using the directory structure
my %command_map = (
    rename => 'Sx::Command::Rename',
);

$Sx::Command::SUB_COMMAND_MAPPING = \%command_map;

1;
