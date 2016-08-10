package RefImp::Project::Command::BaseWithMany;

use strict;
use warnings;

use RefImp;

class RefImp::Project::Command::BaseWithMany { 
    is => 'Command::V2',
    is_abstract => 1,
    has_input => {
        projects => {
            is => 'RefImp::Project',
            is_many => 1,
            shell_args_position => 1,
            doc => 'Projects to use. Use ids or names.',
        },
    },
};

1;

