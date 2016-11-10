package RefImp::Command;

use strict;
use warnings;

use RefImp;

class RefImp::Command {
    is => 'Command::Tree',
};

# This map allows the top-level commands to be set
# instead of using the directory structure
my %command_map = (
    'clone' => 'RefImp::Clone::Command',
    'project' => 'RefImp::Project::Command',
);

$RefImp::Command::SUB_COMMAND_MAPPING = \%command_map;

1;

