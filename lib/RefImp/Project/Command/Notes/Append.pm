package RefImp::Project::Command::Notes::Append;

use strict;
use warnings 'FATAL';

use IO::File;

class RefImp::Project::Command::Notes::Append {
    is => 'RefImp::Project::Command::BaseWithMany',
    has_input => {
        content => {
            is => 'Text',
            doc => 'Content to add to project(s) notes files.',
        },
    },
    doc => 'add content to projects notes files',
};

sub _before_execute {
    $_[0]->status_message('Append projects notes files...');
    $_[0]->status_message("Content:\n%s", $_[0]->content);
}

sub _execute_with_project {
    my ($self, $project) = @_;
    $self->status_message('Project: %s', $project->name);

    my $notes_file_path = $project->notes_file_path;
    my $notes_fh = IO::File->new($notes_file_path, 'a');
    $notes_fh->print("\n".$self->content."\n");
    $notes_fh->close;

    return 1;
}

sub _after_execute { $_[0]->status_message('Append projects notes files...OK') }

1;

