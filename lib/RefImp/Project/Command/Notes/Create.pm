package RefImp::Project::Command::Notes::Create;

use strict;
use warnings 'FATAL';

use IO::File;

class RefImp::Project::Command::Notes::Create {
    is => 'RefImp::Project::Command::Base',
    has_input => {
        prefinisher => {
            is => 'Text',
            doc => 'prefinisher to add to claim project and add to notes',
        },
    },
};

sub execute {
    my $self = shift;
    my $project = $self->project;
    $self->status_message('Create notes file for %s', $project->name);

    my $notes_file_path = $project->notes_file_path;
    my @old_notes_lines;
    if ( -s $notes_file_path ) {
        $self->status_message('Backing up notes file...');
        my $notes_fh = IO::File->new($notes_file_path, 'r');
        my $old_notes_fh = IO::File->new($notes_file_path.'.old', 'w');
        while ( my $line = $notes_fh->getline ) {
            $old_notes_fh->print($line);
            push @old_notes_lines, $line;
        }
        $old_notes_fh->close;
        $notes_fh->close;
    }

    my $clone = RefImp::Clone->get(name => $project->name);
    $self->warning_message('Failed to find clone for %s', $project->name) if not $clone;
    my @time = localtime;

    unlink $notes_file_path;
    my $notes_fh = IO::File->new($notes_file_path, 'w');
    $notes_fh->printf("\nCLONE= %s\n", $project->name);
    $notes_fh->printf("CHROMOSOME= %s\n", ($clone ? $clone->chromosome : 'unknown'));
    $notes_fh->printf("SORTER= %s\n", $self->prefinisher);
    $notes_fh->print("FINISHER= \n");
    $notes_fh->printf("PREFINISH INITIATED ON %s\n", sprintf('%02s/%02s/%02s', $time[4], $time[3], $time[5] - 100));
    $notes_fh->print("~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~\n");

    for my $line ( @old_notes_lines ) {
        $notes_fh->print($line);
    }
    $notes_fh->print("\n");

    $notes_fh->close;

    $self->status_message('Notes file: %s', $notes_file_path);
    return 1;
}

1;

