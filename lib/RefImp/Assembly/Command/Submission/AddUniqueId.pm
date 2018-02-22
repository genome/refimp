package RefImp::Assembly::Command::Submission::AddUniqueId;

use strict;
use warnings 'FATAL';

use YAML;

class RefImp::Assembly::Command::Submission::AddUniqueId {
    is => 'Command::V2',
    has => {
        submission_yml => { is => 'Text', doc => 'Assembly submission YAML file.' },
    },
    doc => 'add unique id to submission yaml',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    my $yml = $self->submission_yml;
    $self->fatal_message('') if not -s $yml;
    my $info = YAML::LoadFile($yml);
    $self->fatal_message('Unique id already exists in YAML file: %s', $info->{unique_id}) if $info->{unique_id};
    $info->{unique_id} = UR::Object::Type->autogenerate_new_object_id_uuid;
    YAML::DumpFile($yml, $info);

    $self->status_message('Add unique id to YML...OK');
    1;
}

1;
