package RefImp::Command;

use strict;
use warnings;

use RefImp;

class RefImp::Command {
    #is => 'RefImp::Command::Base',
    is => 'Command::Tree',
};

# This map allows the top-level genome commands to be whatever
# we wish, instead of having to match the directory structure.
my %command_map = (
    'clone' => 'RefImp::Clone::Command',
    'project' => 'RefImp::Project::Command',
);

$RefImp::Command::SUB_COMMAND_MAPPING = \%command_map;

1;

