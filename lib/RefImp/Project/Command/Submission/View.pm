package RefImp::Project::Command::Submission::View;

use strict;
use warnings;

use Util::Tablizer;

class RefImp::Project::Command::Submission::View { 
    is => 'Command::V2',
    has_input => {
        submission => {
            is => 'RefImp::Project::Submission',
            shell_args_position => 1,
            doc => 'Submission record to show.',
        },
    },
    doc => 'view a submission record',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;
    print join("\n", $self->get_submission_table, $self->load_submit_form);
}

sub get_submission_table {
    my $self = shift;
    Util::Tablizer->format([
        map({ [ sprintf('%s:', uc('project '.$_)), $self->submission->project->$_ ] } (qw/ name id /)),
        map({ [ sprintf('%s:', uc($_)), ($self->submission->$_ // 'NaN') ] } (qw/ project_size phase submitted_on directory /)),
    ]);
}

sub load_submit_form {
    my $self = shift;

    if ( not $self->submission->directory or not -s $self->submission->directory ) {
        return "Submission directory not defined or does not exist!\n";
    }

    my $submit_form_file = $self->submission->submit_form_file;
    if ( not -s $submit_form_file ) {
        $submit_form_file = $self->submission->legacy_submit_form_file;
        if ( not -s $submit_form_file ) {
            return "No submission form in directory!\n";
        }
   }

   my $fh = IO::File->new($submit_form_file, 'r');
   $self->fatal_message('Failed to open %s', $submit_form_file) if not $fh;
   my $form = join('', $fh->getlines);
   $fh->close;
   $form;
}

1;
