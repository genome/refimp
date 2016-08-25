package RefImp::Project::Command::Makecon;

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;
use File::Spec;
use RefImp::Ace::Directory;
use RefImp::Clone::Submissions;

class RefImp::Project::Command::Makecon {
    is => 'RefImp::Project::Command::Base',
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
    doc => 'get project consensus sequence',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message('Makecon...');

    $self->status_message('Project:  %s', $self->project->name);
    $self->status_message('Status: %s', $self->project->status);

    my $seqs = $self->_get_sequences;
    $self->_write_seqs($seqs);

    $self->status_message('Makecon...done');
    return 1;
}

sub _get_sequences {
    my $self = shift;

    my $seqs = $self->_get_sequence_from_most_recent_submission;
    return $seqs if $seqs;

    $seqs = $self->_get_sequence_from_most_recent_ace_file;
    return $seqs if not $seqs;

    $self->fatal_message('Failed to get sequences for %s', $self->project->name);
}

sub _get_sequence_from_most_recent_submission {
    my $self = shift;

    my $clone = RefImp::Clone->get(name => $self->project->name);
    my $analysis_dir = RefImp::Clone::Submissions->analysis_directory_for_clone($clone);
    return if not $analysis_dir;

    my @submit_dirs = sort { $b cmp $a } glob( File::Spec->join($analysis_dir, '20*') );
    if ( not @submit_dirs ) {
        $self->warning_message("Can't figure out dated submission path in %s", $analysis_dir);
        return;
    }
    
    my ($whole_contig_file) = glob( File::Spec->join($submit_dirs[0], "*.whole.contig") );
    if ( not $whole_contig_file ) {
        $self->fatal_message("No 'whole.contig' file in %s", $submit_dirs[0]);
        return;
    }

    my $io = Bio::SeqIO->new(-format => 'Fasta', -file => $whole_contig_file);
    my @seqs;
    while (my $seq = $io->next_seq) {
        push @seqs, $seq;
    }

    return \@seqs;
}

sub _get_sequence_from_most_recent_ace_file {
    my $self = shift;

    my $project_directory = RefImp::Clone->project_directory_for_name( $self->project->name );
    if ( not $project_directory or not -d $project_directory ) {
        $self->warning_message('No project directory for %s', $self->proejct->name);
        return;
    }

    # FIXME move to project
    my $edit_dir = File::Spec->join($project_directory, 'edit_dir');
    my $ace_dir = RefImp::Ace::Directory->new(path => $edit_dir);
    $self->fatal_message("Failed to get ace directory object!") unless $ace_dir;

    my $acefile = $ace_dir->recent_acefile;
    if ( not $acefile or not -s $acefile ) {
        $self->warning_message("No recent ace in %s", $edit_dir);
        return;
    }

    my $ace = GSC::IO::Assembly::Ace->new(input_file => $acefile);
    $self->fatal_message("Failed to open ace file: %s", $acefile) if not $ace;

    my $prefix = $self->{prefix};
    my ($name) = basename $acefile =~ /^(\S+?)\./;
    $prefix = $prefix ? "$name." : '';

    my %ctg_pad_seqs = $ace->contig_names_and_padded_seqs();
    my @seqs;
    for my $ctg_name ( sort { ($a=~/Contig(\S+)/)[0] <=> ($b=~/Contig(\S+)/)[0] } keys %ctg_pad_seqs) {
        my $seq = $ctg_pad_seqs{$ctg_name}; 
        $seq =~ s/\*//g; 
        $seq =~ s/x/n/gi;
        push @seqs, Bio::Seq->new(-seq => $seq, -id => $prefix.$ctg_name);
    }

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

