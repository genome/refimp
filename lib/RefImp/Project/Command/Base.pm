package RefImp::Project::Command::Base;

use strict;
use warnings;

use RefImp;

class RefImp::Project::Command::Base { 
    is => 'Command::V2',
    is_abstract => 1,
    has_input => {
        project => {
            is => 'RefImp::Project',
            shell_args_position => 1,
            doc => 'Project to use. Use id or name.',
        },
    },
    has_optional_calculated => {
        clone => {
            calculate_from => [qw/ project /],
            calculate => q| RefImp::Clone->get(name => $project->name); |,
        },
    },
    doc => 'base class for commands that work with a project',
};

1;

