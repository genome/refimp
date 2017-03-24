package RefImp::Project::Command::Presubmit;

use strict;
use warnings;

use MIME::Lite;
use RefImp::Project::Submissions::Info;
use RefImp::Project::Submissions::Form;

class RefImp::Project::Command::Presubmit {
    is => 'RefImp::Project::Command::QaBase',
    has_input => {
        checker_unix_logins => {
            is => 'String',
            is_many => 1,
            doc => 'Unix logins of checkers to apprvoe this project for submit.',
        },
    },
    doc => 'presubmit a project',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub valid_project_statuses { (qw/ finish_start /) }

sub execute {
    my $self = shift;
    $self->status_message('Presubmit project...');

    $self->status_message('Project:  %s', $self->project->name);
    $self->_check_project_status;
    $self->_display_submit_form;
    $self->_send_email;
    $self->project->status('presubmitted');
    $self->status_message('New project status: %s', $self->project->status);

    $self->status_message('Presubmit..OK');
    return 1;
}

sub _display_submit_form {
    my $self = shift;

    my $submit_info = RefImp::Project::Submissions::Info->generate( $self->project );
    my $form = RefImp::Project::Submissions::Form->create($submit_info);
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

    # Finisher/Checkers
    my ($finisher) = $self->project->finishers; # FIXME multiple finishers??
    $self->fatal_message('No finisher assgined to project: %s', $self->project->__display_name__) if not $finisher;

    my @checker_unix_logins = $self->checker_unix_logins;
    my @checkers = RefImp::User->get(name => \@checker_unix_logins);
    if ( @checkers != @checker_unix_logins ) {
        $self->fatal_message('Failed to get all checkers for unix logins: %s', join(' ', $self->checker_unix_logins));
    }

    # Email
    my $msg = MIME::Lite->new(
        To => [ $finisher->email ],
        Cc => [ map { $_->email } @checkers ],
        From => 'no-reply@wustl.edu',
        Subject => sprintf('Presubmit %s', $self->project->__display_name__),
        Type     => 'multipart/mixed'
    ) or die "Can't create Mail::Sender";

    $msg->attach(
        Type =>'TEXT',
        Data => sprintf(
"Project %s has been successfully presubmitted!

Checkers (CC'd), can someone please review this project? When done, submit the project to NCBI with the below command.

\$ refimp project submit %s

Sincerely,
The RefImp Team",
            $self->project->__display_name__, 
            $self->project->name,
        ),
    );

    $msg->send;
}

1;

