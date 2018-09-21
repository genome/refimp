package RefImp::Assembly::Command::Submission::Create;

use strict;
use warnings 'FATAL';

use RefImp::Assembly::Submission;

class RefImp::Assembly::Command::Submission::Create {
    is => 'Command::V2',
    has_input => {
        submission_yml => {
            is => 'File',
            doc => 'YAML file with submission info. It must be in the assembly submission directory. Use the "refimp assembly submission yaml" command for a template or help (--h).',
        },
    },
    has_optional_input => {
        submitted_on => {
            is => 'Date',
            doc => 'Use a different date for the submission. Use format: YYYY-MM-DD.'
        },
    },
    has_output => {
        submission => {
            is => 'RefImp::Assembly::Submission',
            doc => 'Created submission.',
        },
    },
    doc => 'create an assembly submission',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;

    my $submitted_on = $self->submitted_on;
    if ( $submitted_on ) {
        $self->fatal_message('Invalid submitted_on date given! %s', $submitted_on) if $submitted_on !~ /^\d{4}\-\d{2}\-\d{2}$/;
    }
    my $submission = RefImp::Assembly::Submission->get_or_create_from_yml($self->submission_yml);
    if ( my @errors = $submission->__errors__ ) {
        $self->fatal_message( join("\n", map { $_->__display_name__ } @errors) );
    }
    $submission->submitted_on($submitted_on) if $submitted_on;
    $self->submission($submission);

    $self->status_message('Created submission record: %s', $submission->__display_name__);
    1;
}

1;
