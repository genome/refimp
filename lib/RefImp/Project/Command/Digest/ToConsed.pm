package RefImp::Project::Command::Digest::ToConsed;

use strict;
use warnings 'FATAL';

use File::Spec;
use RefImp::Project::Digest;
use RefImp::Project::Digest::Enzymes;
use RefImp::Project::Digest::Reader;

class RefImp::Project::Command::Digest::ToConsed {
    is => 'RefImp::Project::Command::Base',
    doc => 'extract digest info from sizes file',
};

sub help_detail {
    <<HELP;
Converts .sizes files in project digest directoryt into Consed friendly fragSizes files. Links the most recent fragSizes file to fragSizes.txt in the edit_dir.
HELP
}

sub execute {
    my $self = shift;
    $self->status_message('Digest sizes to consed...');

    my $project = $self->project;
    $self->status_message('Project: %s', $project->__display_name__);

    my $edit_dir = $project->edit_directory;
    $self->fatal_message('No project edit_dir directory!') if not -d $edit_dir;
    my $digest_directory = $project->digest_directory;
    $self->fatal_message('No project diest directory!') if not -d $digest_directory;

    my $dh = IO::Dir->new($digest_directory);
    my %digests;
    while ( my $file_name = $dh->read ) {
        next if $file_name !~ /\.sizes$/;
        my $sizes_file = File::Spec->join($digest_directory, $file_name);
        $self->status_message('Reading: %s', $sizes_file);

        my $reader = RefImp::Project::Digest::Reader->new(file => $sizes_file);
        while ( my $digest = $reader->next_for_project($project->name) ) {
            push @{$digests{ $digest->date }}, $digest;
        }
    }
    $dh->close;

    my $frag_sizes_file_template = File::Spec->join($project->edit_directory, 'fragSizes%s.txt');
    my @frag_sizes_files;
    foreach my $date ( keys %digests ) {
        my $frag_sizes_file = sprintf($frag_sizes_file_template, $date);
        push @frag_sizes_files, $frag_sizes_file;
        $self->status_message('fragSizes file: %s', $frag_sizes_file);
        unlink $frag_sizes_file if -e $frag_sizes_file;
        foreach my $digest ( @{$digests{$date}} ) {
            my $enzyme = $digest->enzyme;
            $self->status_message('Adding digest: %s', $enzyme);
            $self->fatal_message('Failed to get enzyme for %s', $digest->{project_header}) if not $enzyme;
            my $fh = IO::File->new($frag_sizes_file, 'a');
            $fh->print(">$enzyme\n");
            $fh->print( join("\n", @{$digest->{bands}}, '') );
            $fh->close;
        }
    }

    my $main_frag_sizes_file = sprintf($frag_sizes_file_template, '');
    unlink $main_frag_sizes_file if -e $main_frag_sizes_file;
    my ($most_recent_frag_sizes_file) = sort { $b cmp $a } @frag_sizes_files;
    $self->status_message('Linking fragSizes.txt to %s', $most_recent_frag_sizes_file);
    symlink $most_recent_frag_sizes_file, $main_frag_sizes_file;

    $self->status_message('Digest sizes to consed...OK');
    return 1
}

1;

