package RefImp::Project::Command::Submission::QaRequest;

use strict;
use warnings;

use RefImp::Project::Submission::Info;
use RefImp::Project::Submission::Form;

class RefImp::Project::Command::Submission::QaRequest {
    is => 'RefImp::Project::Command::Base',
    has_input => {
        checker_unix_logins => {
            is => 'String',
            is_many => 1,
            doc => 'Unix logins of checkers to apprvoe this project for submit.',
        },
    },
    doc => 'request qa review for a project',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub valid_project_statuses { (qw/ finish_start /) }

sub execute {
    my $self = shift;
    $self->status_message('Presubmit project...');

    $self->status_message('Project:  %s', $self->project->name);
    $self->fatal_message("Incorrect project status to request QA: %s", $self->project->status) if $self->project->status ne 'finish_start';
    $self->_display_submit_form;
    $self->_send_email;
    $self->project->status('presubmitted');
    $self->status_message('New project status: %s', $self->project->status);

    $self->status_message('Presubmit..OK');
    return 1;
}

sub _display_submit_form {
    my $self = shift;

    my $submit_info = RefImp::Project::Submission::Info->generate( $self->project );
    my $form = RefImp::Project::Submission::Form->create($submit_info);
    $self->fatal_message('Failed to generate submissions form!') if not $form;

    print STDOUT "$form\nProceed with presubmit? ([Y]/n) ";
    my $response = <STDIN>;
    chomp $response;
    if ( not $response or $response !~ /^y/i ) {
        $self->fatal_message('Request to not presubmit...exiting');
    }
}

sub _send_email {
    my $self = shift;
    $self->warning_message('Not sending email for QA request currently. Please contact reviewer.');
}

1;

