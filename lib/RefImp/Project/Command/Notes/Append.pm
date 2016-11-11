package RefImp::Project::Command::Notes::Append;

use strict;
use warnings 'FATAL';

use IO::File;

class RefImp::Project::Command::Notes::Append {
    is => 'RefImp::Project::Command::BaseWithMany',
    has_optional_input => {
        content => {
            is => 'Text',
            doc => 'Append content to projects notes files.',
        },
        from_file => {
            is => 'Text',
            doc => 'Read content from a file and append it to projects notes files.',
        },
    },
    doc => 'add content to projects notes files',
};

sub _before_execute {
    my $self = shift;
    $self->status_message('Append projects notes files...');

    if ( not $self->content and not $self->from_file ) {
        $self->fatal_message('Please provide content or from_file!');
    }
    elsif ( $self->from_file ) {
        $self->status_message("Loading content from: %s", $self->from_file);
        open(my $fh, '<', $self->from_file) or $self->fatal_message('Failed to open file: %s', $self->from_file);
        local $/ = undef;
        $self->content( <$fh> );
        close $fh;
    }
    $self->status_message("Content:\n%s", $self->content);
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

