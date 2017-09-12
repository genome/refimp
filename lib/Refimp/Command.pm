package Refimp::Command;

use strict;
use warnings;

class Refimp::Command {
    is => 'Command::Tree',
};

# This map allows the top-level commands to be set
# instead of using the directory structure
my %command_map = (
    assembly => 'Refimp::Assembly::Command',
    cron => 'Refimp::Cron::Command',
    project => 'Refimp::Project::Command',
    taxon => 'Refimp::Taxon::Command',
    tenx => 'Refimp::Tenx::Command',
);

$Refimp::Command::SUB_COMMAND_MAPPING = \%command_map;

1;

