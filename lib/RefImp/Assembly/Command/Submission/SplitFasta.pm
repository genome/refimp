package RefImp::Assembly::Command::Submission::SplitFasta;

use strict;
use warnings 'FATAL';

use Bio::SeqIO;
use Encode;
use File::Basename;

class RefImp::Assembly::Command::Submission::SplitFasta {
    is => 'Command::V2',
    has_input => {
        fasta_file => { is => 'Text', doc => 'Fasta file to split', },
        output_fasta_file_pattern => { is => 'Text', doc => 'Pattern for output fast file names. Must have a "%d" for file number. Example: contigs.%02d.fa', },
    },
    has_optional_input => {
        max_seq_count => { is => 'Text', doc => 'Maximum number of sequences to put in a fasta file.', },
        max_file_size => { is => 'Text', doc => 'Maximum file size of fastas.', },
    },
    has_output => {
        output_fasta_files => { is => 'Text', is_many => 1, },
    },
    has_optional_transient => {
        output_fasta_file_pattern => { is => 'Text', },
    },
    doc => 'split fastas by count and size',
};

sub help_detail { $_[0]->__meta__->doc }

sub __errors__ {
    my $self = shift;

    my @errors = $self->SUPER::__errors__;
    return @errors if @errors;

    $self->fatal_message('No max_seq_count or max_file_size set!') if not $self->max_seq_count and not $self->max_file_size;
    $self->fatal_message('Fasta file does not exist! %s', $self->fasta_file) if not -s $self->fasta_file;
    $self->fatal_message('Invalid output fasta file pattern! %s', $self->output_fasta_file_pattern) if $self->output_fasta_file_pattern !~ /%\d*[ds]/;
    my ($basename, $dir) = File::Basename::fileparse($self->output_fasta_file_pattern);
    $self->fatal_message('Output directory does not exists! %s', $dir) if not -d $dir;

    return;
}

sub execute {
    my $self = shift;

    my $reader = Bio::SeqIO->new(
        -file => $self->fasta_file,
        -format => 'Fasta',
    );
    my $writer = $self->open_next_writer;

    my $seq_cnt = 0;
    my $file_sz = 0;
    while ( my $seq = $reader->next_seq ) {
        my $est_seq_sz = length(Encode::encode_utf8(join("", ">", $seq->display_id, " ", $seq->desc, "\n", $seq->seq, "\n")));
        $self->fatal_message('Max file size (%s) prevents writing seq %s!', $self->max_file_size, $seq->display_id) if $self->max_file_size and $est_seq_sz > $self->max_file_size;
        if ( ( $self->max_seq_count and $seq_cnt >= $self->max_seq_count )
                or ( $self->max_file_size and $file_sz + $est_seq_sz > $self->max_file_size )) {
            $writer->close;
            $writer = $self->open_next_writer;
            $seq_cnt = 0;
            $file_sz = 0;
        }

        $seq_cnt++;
        $file_sz += $est_seq_sz;
        $writer->write_seq($seq);
    }

    $reader->close;
    $writer->close;
    1;
}

sub open_next_writer {
    Bio::SeqIO->new(
        -file => ">".$_[0]->next_output_fasta_file,
        -format => 'Fasta',
        -flush => 0,
    );
}

sub next_output_fasta_file {
    my $self = shift;

    my @output_fasta_files = $self->output_fasta_files;
    my $file_count = @output_fasta_files + 1;
    push @output_fasta_files, sprintf($self->output_fasta_file_pattern, (@output_fasta_files + 1));
    $self->output_fasta_files(\@output_fasta_files);

    $output_fasta_files[$#output_fasta_files];
}

1;
