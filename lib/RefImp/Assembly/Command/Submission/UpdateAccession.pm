package RefImp::Assembly::Command::Submission::UpdateAccession;

use strict;
use warnings;

class RefImp::Assembly::Command::Submission::UpdateAccession { 
    is => 'Command::V2',
    has_input => {
        submission => {
            is => 'RefImp::Assembly::Submission',
            shell_args_position => 1,
            doc => 'The submission to update.',
        },
        value => {
            is => 'String',
            shell_args_position => 2,
            doc => 'The accession id to assign to the submission.',
        },
    },
    doc => 'update assembly submission accession',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    $self->status_message('Submission: %s', $self->submission->__display_name__);
    $self->status_message('Old accession: %s', $self->submission->accession_id // 'NULL');
    $self->submission->accession_id( $self->value );
    $self->status_message('New accession: %s', $self->submission->accession_id);
    1;
}

1;
