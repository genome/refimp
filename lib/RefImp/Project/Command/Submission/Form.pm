package RefImp::Project::Command::Submission::Form;

use strict;
use warnings;

class RefImp::Project::Command::Submission::Form { 
    is => 'Command::V2',
    has_input => {
        project => {
            is => 'RefImp::Project',
            shell_args_position => 1,
            doc => 'PRoject to get the submit form.',
        },
    },
    doc => 'show the submision form for a project',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;

    my @submissions = $self->project->submissions(-order_by => 'submitted_on');
    if ( not @submissions ) {
        $self->fatal_message('No submissions found for %s', $self->project->__display_name__) and return 
    }

    my $submission = $submissions[$#submissions];
    print $self->load_submit_form($submission);
}

sub load_submit_form {
    my ($self, $submission) = @_;

    if ( not $submission->directory or not -s $submission->directory ) {
       $self->fatal_message('No directory for submission %s.', $submission->__display_name__);
    }

    my $submit_form_file = $submission->submit_form_file;
    if ( not -s $submit_form_file ) {
        $submit_form_file = $submission->legacy_submit_form_file;
        if ( not -s $submit_form_file ) {
            $self->fatal_message('No submit form file found for ', $submission->__display_name__);
        }
   }

   my $fh = IO::File->new($submit_form_file, 'r');
   $self->fatal_message('Failed to open %s', $submit_form_file) if not $fh;
   my $form = join('', $fh->getlines);
   $fh->close;
   $form;
}

1;
