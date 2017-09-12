package Refimp::Project::Command::Makecon;

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;
use File::Basename;
use File::Spec;
use IO::File;
use Refimp::Ace::Directory;
use Refimp::Ace::Reader;

class Refimp::Project::Command::Makecon {
    is => 'Refimp::Project::Command::Base',
    has_input => {
        finished_region_only => {
            is => 'Boolean',
            default => 0,
            doc => 'If project is submitted, retrieve only the finished portion vs the entire contig sequence.',
        },
    },
    has_output => {
        output_file => {
            is => 'Text',
            is_optional => 1,
            doc => 'File name to putput consensus sequence. Defaults to "$PROJECTNAME.con" in current directory.'
        },
    },
    has_transient_optional => {
        retrieved_from => { is => 'Text', },
    },
    doc => 'get project consensus sequence',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message('Makecon...');

    $self->status_message('Project:  %s', $self->project->name);
    $self->status_message('Status: %s', $self->project->status);

    my $seqs = $self->_get_sequences;
    $self->status_message('Sequence retrieved from %s', $self->retrieved_from);

    $self->_write_seqs($seqs);

    $self->status_message('Makecon...done');
    return 1;
}

sub _get_sequences {
    my $self = shift;

    my $seqs = $self->_get_sequence_from_most_recent_submission;
    return $seqs if $seqs;

    $seqs = $self->_get_sequence_from_most_recent_ace_file;
    return $seqs if $seqs;

    $self->fatal_message('Failed to get sequences for %s', $self->project->name);
}

sub _get_sequence_from_most_recent_submission {
    my $self = shift;

    my @submissions = sort { $b->submitted_on cmp $a->submitted_on } $self->project->submissions;
    return if not @submissions;

    my $submission = $submissions[0];
    my $directory = $submission->directory;
    $self->warning_message('No directory for %s', $submission->__display_name__) and return if not $directory;
    $self->warning_message('Submission directory does not exists for %s', $submission->__display_name__) and return if not -d $directory;

    my ($whole_contig_file) = glob( File::Spec->join($directory, "*.whole.contig") );
    if ( not $whole_contig_file ) {
        $self->fatal_message("No 'whole.contig' file for %s", $submission->__display_name__);
        return;
    }

    my $io = Bio::SeqIO->new(-format => 'Fasta', -file => $whole_contig_file);
    my @seqs;
    while (my $seq = $io->next_seq) {
        push @seqs, $seq;
    }

    $self->retrieved_from($whole_contig_file);
    return \@seqs;
}

sub _get_sequence_from_most_recent_ace_file {
    my $self = shift;

    my $project_directory = $self->project->directory;
    if ( not $project_directory or not -d $project_directory ) {
        $self->warning_message('No project directory for %s', $self->project->name);
        return;
    }

    my $ace_dir = Refimp::Ace::Directory->create(project => $self->project);
    $self->fatal_message("Failed to get ace directory object!") unless $ace_dir;

    my $acefile = $ace_dir->recent_acefile;
    if ( not $acefile or not -s $acefile ) {
        $self->warning_message("No recent ace in %s", $ace_dir->path);
        return;
    }

    my $fh = IO::File->new($acefile, 'r');
    $self->fatal_message("Failed to open ace file: %s", $acefile) if not $fh;
    my $reader = Refimp::Ace::Reader->new($fh);
    $self->fatal_message("Failed to create ace reader for ace file: %s", $acefile) if not $reader;

    my $prefix = $self->{prefix};
    my $ace = File::Basename::basename($acefile);
    my ($name) = $ace =~ /^(\S+?)\./;
    $prefix = $prefix ? "$name." : '';

    my @seqs;
    while ( my $contig = $reader->next_object_of_type('contig') ) {
        my $seq = $contig->{consensus};
        $seq =~ s/\*//g; 
        $seq =~ s/x/n/gi;
        push @seqs, Bio::Seq->new(-seq => $seq, -id => $prefix.$contig->{name});
    }

    # sort { ($a->id =~ /Contig(\S+)/)[0] <=> ($b->id =~ /Contig(\S+)/)[0] } @seqs
    $self->retrieved_from($acefile);
    \@seqs;
}

sub _write_seqs {
    my ($self, $seqs) = @_;

    $self->output_file( join('.', $self->project->name, 'con') ) if not $self->output_file;
    my $output_file = $self->output_file;
    $self->status_message('Output file: %s', $output_file);

    my $seq_io = Bio::SeqIO->new(-file => ">$output_file", -format => 'Fasta');
    $seq_io->write_seq(@{$seqs});
    chmod 0664, $output_file;

    $self->fatal_message('Failed to write file: %s', $output_file) unless -s $output_file;
}

1;

