package RefImp::Assembly::Command::Submission::View;

use strict;
use warnings;

use RefImp::Util::Tablizer;

class RefImp::Assembly::Command::Submission::View { 
    is => 'Command::V2',
    has_input => {
        submission => {
            is => 'RefImp::Assembly::Submission',
            shell_args_position => 1,
            doc => 'Submission record to show.',
        },
    },
    doc => 'view a submission record',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;
    my $submission = $self->submission;
    print join(
        "\n",
        'ASSEMBLY SUBMISSION RECORD',
        RefImp::Util::Tablizer->format([
            map({ [ sprintf('%s:', uc($_)), ( $submission->$_ // 'NaN' ) ] } (qw/ id ncbi_version accession_id bioproject biosample submitted_on directory /)),
            ]),
        "SUBMISSION YAML:",
        ( $submission->submission_yml || 'NaN' ),
    );
}

1;
