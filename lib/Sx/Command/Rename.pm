package Sx::Command::Rename;

use strict;
use warnings 'FATAL';

use Bio::SeqIO;

class Sx::Command::Rename {
    is => 'Command::V2',
    has_input => {
        input => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'Input fasta.',
        },
    },
    has_output => {
        output => {
            is => 'Text',
            shell_args_position => 2,
            doc => 'Output fasta.',
        },
    },
    has_param => {
        prepend => {
            is => 'Text',
            doc => 'String to prepend to sequences.',
        },
    },
    doc => 'Rename sequences.',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message("Rename sequences...");

    $self->status_message("Input fasta: %s", $self->input);
    my $seqin = Bio::SeqIO->new(
        -file => $self->input,
        -format => 'Fasta',
    );

    $self->status_message("Output fasta: %s", $self->output);
    my $ofh = IO::File->new($self->output, 'w');
    $self->fatal_message("Failed to open file for writing: %s", $self->output) if not $ofh;

    my $value = $self->prepend;
    $self->status_message("Prepending to sequences: %s", $self->prepend);

    while ( my $seq = $seqin->next_seq() ) {
        #$ofh->print( join('', '>', $value, $seq->display_id, ( $seq->desc // , "\n") );
        $ofh->printf(">%s%s%s\n%s\n", $value, $seq->display_id, ( $seq->desc ? ' '.$seq->desc : '' ), $seq->seq);
    }
    $ofh->close;

    $self->status_message("Rename sequences...DONE");
    1;
}

1;
