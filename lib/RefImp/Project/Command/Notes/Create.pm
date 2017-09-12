package Refimp::Project::Command::Notes::Create;

use strict;
use warnings 'FATAL';

use IO::File;

class Refimp::Project::Command::Notes::Create {
    is => 'Refimp::Project::Command::BaseWithMany',
    has_input => {
        prefinisher => {
            is => 'Text',
            doc => 'prefinisher to add to claim project and add to notes',
        },
    },
    doc => 'add basic notes file for a project',
};

sub _before_execute { $_[0]->status_message('Create projects notes files...') }

sub _execute_with_project {
    my ($self, $project) = @_;
    $self->status_message('Project: %s', $project->name);

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

    my $taxonomy = $project->taxonomy;
    my @time = localtime;

    unlink $notes_file_path;
    my $notes_fh = IO::File->new($notes_file_path, 'w');
    $notes_fh->printf("\nCLONE= %s\n", $project->name);
    $notes_fh->printf("CHROMOSOME= %s\n", ($taxonomy ? $taxonomy->chromosome : 'unknown'));
    $notes_fh->printf("SORTER= %s\n", $self->prefinisher);
    $notes_fh->print("FINISHER= \n");
    $notes_fh->printf("PREFINISH INITIATED ON %s\n", sprintf('%02s/%02s/%02s', $time[4], $time[3], $time[5] - 100));
    $notes_fh->print("~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~\n");

    for my $line ( @old_notes_lines ) {
        $notes_fh->print($line);
    }
    $notes_fh->print("\n");
    $notes_fh->close;

    return 1;
}

sub _after_execute { $_[0]->status_message('Create projects notes files...OK') }

1;

