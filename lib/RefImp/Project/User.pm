package RefImp::Project::User;

use strict;
use warnings 'FATAL';

class RefImp::Project::User {
    table_name => 'projects_users',
    id_by => {
        project_id => { is => 'Text', },
        user_id => { is => 'Text', },
        purpose => { is => 'Text', valid_values => [qw/ finisher prefinisher saver /], },
    },
    has => {
        project => { is => 'RefImp::Project', id_by => 'project_id', },
        user => { is => 'RefImp::User', id_by => 'user_id', },
    },
    has_optional => {
        status => { is => 'Text', len => 264, },
    },
    data_source => RefImp::Config::get('refimp_ds'),
};

sub valid_purposes { @{$_[0]->__meta__->property_meta_for_name('purpose')->valid_values} }

1;

