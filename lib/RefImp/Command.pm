package RefImp::Command;

use strict;
use warnings;

class RefImp::Command {
    is => 'Command::Tree',
};

# This map allows the top-level commands to be set
# instead of using the directory structure
my %command_map = (
    assembly => 'RefImp::Assembly::Command',
    cron => 'RefImp::Cron::Command',
    project => 'RefImp::Project::Command',
    taxon => 'RefImp::Taxon::Command',
);

$RefImp::Command::SUB_COMMAND_MAPPING = \%command_map;

1;

