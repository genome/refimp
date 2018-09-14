package Pacbio::Command::Assembly::InsertMissingContigs;

use strict;
use warnings 'FATAL';

use Bio::SeqIO;
use List::Util;
use List::MoreUtils;
use Set::Scalar;
use Sx::Index::Fai;

class Pacbio::Command::Assembly::InsertMissingContigs {
    is => 'Command::V2',
    has_input => {
        primary_fasta => {
            is => 'Text',
            doc => 'Primary contigs fasta file.',
        },
        haplotigs_fasta => {
            is => 'Text',
            doc => 'Haplotigs contigs fasta file.',
        },
    },
    has_optional_input => {
        primary_fai => {
            is => 'Text',
            doc => 'Primary contigs fasta index file. If not given, ".fai" will be appended to the primary contigs fasta file name.',
        },
        haplotigs_fai => {
            is => 'Text',
            doc => 'Haplotigs contigs fasta index file. If not given, ".fai" will be appended to the haplotigs contigs fasta file name.',
        },
    },
    has_output => {
        output_primary_fasta => {
            is => 'Text',
            doc => 'Output primary contigs fasta file.',
        },
        output_haplotigs_fasta => {
            is => 'Text',
            doc => 'Output haplotigs fasta file.',
        },
    },
    has_optional_transient => {
        _haplotigs_fai => { is => 'Sx::Index::Fai', },
    },
    doc => 'insert missing primary contigs from haplotigs',
};

sub __init__ {
    my ($self) = @_;

    for my $type (qw/ primary haplotigs /) {
        # input fasta
        my $fasta_method = join('_', $type, 'fasta');
        $self->fatal_message("File $fasta_method does not exist!") if not -s $self->$fasta_method;
        # input fai
        my $fai_method = join('_', $type, 'fai');
        if ( not $self->$fai_method ) {
            $self->$fai_method( join('.', $self->$fasta_method, 'fai') );
        }
        $self->fatal_message("File $fai_method does not exist!") if not -s $self->$fai_method;
        # output fasta
        my $method = join('_', 'output', $type, 'fasta');
        my $fasta = $self->$method;
        $self->fatal_message('Output %s fasta exists: %s. Please change detination, or remove it.', $type, $fasta) if -s $fasta;
    }
}

sub execute {
    my ($self) = @_;

    $self->__init__;
    my $ctgs = $self->_get_primary_contigs_set_from_fai;
    my $haplotigs = $self->_get_haplotigs_set_from_fai;
    my $missing_ctgs = $haplotigs->difference($ctgs);
    $self->fatal_message("No missing contigs found!") if not $missing_ctgs->members;
    $self->_write_contigs($ctgs, $missing_ctgs);
    1;
}

sub _get_primary_contigs_set_from_fai {
    my ($self) = @_;

    my $fai = Sx::Index::FaiReader->new($self->primary_fai);
    my $set = Set::Scalar->new;
    while ( my $e = $fai->read ) {
        $set->insert($e->{id});
    }

    $set;
}

sub _get_haplotigs_set_from_fai {
    my ($self) = @_;

    my $fai = Sx::Index::Fai->new($self->haplotigs_fai);
    $self->_haplotigs_fai($fai);
    $fai->reader->reset;

    my $set = Set::Scalar->new;
    while ( my $e = $fai->reader->read ) {
        my $haplotig_id_tokens = $self->haplotig_id_tokens($e->{id});
        $set->insert( $haplotig_id_tokens->[0].$haplotig_id_tokens->[2] );
    }

    $set;
}

sub _write_contigs {
    my ($self, $ctgs, $missing_ctgs) = @_;

    # Seq INs
	my $p_seqin = Bio::SeqIO->new(
		-file => $self->primary_fasta,
		-format => 'Fasta',
	);
	my $hfh = IO::File->new($self->haplotigs_fasta, 'r');
	$self->fatal_message('Failed to open haplotigs fasta! %s', $self->haplotigs_fasta) if not $hfh;
	my $h_seqin = Bio::SeqIO->new(
		-fh => $hfh,
		-format => 'Fasta',
	);

    # Seq OUTs
	my $p_seqout = Bio::SeqIO->new(
        -format => 'Fasta',
        -file => '>'.$self->output_primary_fasta,
    );
	my $h_seqout = Bio::SeqIO->new(
        -format => 'Fasta',
        -file => '>'.$self->output_haplotigs_fasta,
    );

    for my $ctg_id ( sort { $a cmp $b } ($ctgs->members, $missing_ctgs->members) ) {
        if ( $ctgs->has($ctg_id) ) {
            # Contig should be next in primary fasta - write it to the output primary fasta
            my $seq = $p_seqin->next_seq;
            $self->fatal_message('Expected primary contig %s but got %s', $ctg_id, $seq->id) if $ctg_id ne $seq->id;
            $p_seqout->write_seq($seq);

            # Get entries from haplotig fai for this primary id, write them to haplotig fasta
            my $entries = $self->_haplotigs_fai->entries_for_id_regex('^'.$ctg_id.'_');
            next if not $entries; # dunno, could happen?
            for my $entry ( @$entries ) {
                my $seq = $h_seqin->next_seq;
                $self->fatal_message('Expected haplotig %s but got %s', $entry->{id}, $seq->id) if $entry->{id} ne $seq->id;
                $h_seqout->write_seq($seq);
            }
        }
        else { # MISSING
            # Get entries from haplotig fai, marking the longest one
            my $entries = $self->_get_haplotigs_for_primary_ctg_id_marking_longest($ctg_id);
            my $i = 1;
            for my $entry ( @$entries ) {
                my $seq = $h_seqin->next_seq;
                $self->fatal_message('Expected haplotig %s but got %s', $entry->{id}, $seq->id) if $entry->{id} ne $seq->id;
                if ( exists $entry->{longest} ) { # longest goes to primary using the ctg id
                    $seq->id($ctg_id);
                    $p_seqout->write_seq($seq);
                }
                else { # others go to the output haplotig, re-numbering them
                    my $haplotig_id_tokens = $self->haplotig_id_tokens($entry->{id});
                    $seq->id( sprintf('%s_%03d%s', $haplotig_id_tokens->[0], $i, $haplotig_id_tokens->[2]) );
                    $h_seqout->write_seq($seq);
                    $i++;
                }
            }
        }
    }
}

sub _get_haplotigs_for_primary_ctg_id_marking_longest {
    my ($self, $ctg_id) = @_;

    my $fai = $self->_haplotigs_fai;
    my $entries = $fai->entries_for_id_regex('^'.$ctg_id.'_');
    $self->fatal_message('No entries for primary contig id: %s', $ctg_id) if not $entries;

    my $lengths = Set::Scalar->new( map { $_->{length} } @$entries );
    my $longest_length = List::Util::max( $lengths->members );
    my $longest = List::MoreUtils::first_value { $_->{length} == $longest_length } @$entries;
    $longest->{longest} = 1;
    $entries
}

sub haplotig_id_tokens {
    my ($self, $haplotig_id) = @_;
    $self->fatal_message("No haplotig id to get tokens!") if not defined $haplotig_id;
    my ($ctg_num, $rest) = split(/_/, $haplotig_id, 2);
    $self->fatal_message("Could not find haplotig number in id: $haplotig_id") if not $rest;
    $rest =~ s/^(\d+)//;
    my $num = "$1";
    $self->fatal_message("Could not find haplotig number in id: $haplotig_id") if not $num;
    [ $ctg_num, $num, $rest ]; # CTG_NUM HAP_NUM REMAINDER
}

1;
