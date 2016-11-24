package RefImp::Project::Submissions::Sequence;

use strict;
use warnings;

use Bio::Seq;
use RefImp::Ace::Reader;
use Params::Validate qw/ :types validate /;

class RefImp::Project::Submissions::Sequence {
    has => {
        project_name => { is => 'Text', },
        ace => { is => 'Text', },
        contig_data => { is => 'ARRAY', },
    },
    has_optional => {
        transposons => { is => 'ARRAY', },
    },
    has_transient_optional => {
        seq => { is => 'Bio::Seq', },
        transposon_excised_seq => { is => 'Bio:Seq', },
    },
};

sub create {
    my $class = shift;
    my %params = validate(@_, {
            project_name => { type => SCALAR, },
            ace => { type => SCALAR, },
            contig_data => { type => ARRAYREF, },
            transposons => { type => ARRAYREF, optional => 1, },
        });

    my $self = $class->SUPER::create(%params);
    return if not $self;

    $self->fatal_message('Ace file does not exist! %s', $self->ace) if not -s $self->ace;
    $self->fatal_message('No contig_data given!') if not @{$self->contig_data};
    $self->fatal_message('Not supporting multiple contigs! %s', join(' ', @{$self->contig_data})) if @{$self->contig_data} > 1;
    $self->_load_seq_from_ace0;
    $self->_create_transposon_excised_seq;

    return $self;
}

sub _load_seq_from_ace0 {
    my $self = shift;

    my $fh = IO::File->new($self->ace, 'r');
    $self->fatal_message("%s\nFailed to open %s", $!, $self->ace) if not $fh;
    my $reader = RefImp::Ace::Reader->new($fh);
    $self->fatal_message('Failed to create ace reader for %s', $self->ace) if not $reader;

    my $contig_data = $self->contig_data->[0];
    my $contig_number = $contig_data->{ContigNumber};
    $self->fatal_message('No ContigNumber in contig data! %s', Data::Dumper::Dumper($contig_data)) if not $contig_number;
    my $contig_name = 'Contig'.$contig_number;
    my $contig;
    while ( my $obj = $reader->next_object_of_type('contig') ) {
        if ( $obj->{name} eq $contig_name ) {
            $contig = $obj;
            last;
        }
    }
    $self->fatal_message('Failed to get contig! %s', $contig_name) if not $contig;
    my $bases = $contig->{consensus};
    $self->fatal_message('Failed to get sequence for contig! %s', $contig_name) if not $bases;

    $bases =~ s/\*//g; # remove pads
    for my $ambiguous_base (qw/ n x /) {
        my $found = index($bases, $ambiguous_base);
        if ( $found == -1 ) {
            $found = index($bases, uc($ambiguous_base));
            next if $found == -1;
        }
        $self->fatal_message('Ace (%s) has ambiguous bases in contig %s!', $self->ace, $contig_name);
    }

    my $seq = Bio::Seq->new(
        -display_id => $self->project_name,
        -desc => sprintf('%s to %s', $contig_data->{ContigFinishedFrom}, $contig_data->{ContigFinishedTo}),
        -seq => $bases,
    );
    $self->fatal_message('Failed to create bio seq!') if not $seq;

    $self->seq($seq);
}

sub _create_transposon_excised_seq {
    my $self = shift;

    # Any transposons?
    my $transposons = $self->transposons;
    if ( not $transposons ) {
        return $self->transposon_excised_seq($self->seq);
    }

    # Gather the seqs with transposons excised out
    my @seqs;
    my $current_seq = $self->seq;
    my $left_pos = 1;
    for my $transposon (
        sort { $a->{TransposonCommentsLastBaseBeforePosition} <=> $b->{TransposonCommentsLastBaseBeforePosition} } @$transposons
    ) {

        next unless $transposon->{TransposonCommentsSequenceRegion} eq 'Finished Region';

        my $left_seq = $current_seq->trunc(1, $transposon->{TransposonCommentsLastBaseBeforePosition} - $left_pos + 1);
        $left_seq->desc( join(' ', $left_pos, 'to', $transposon->{TransposonCommentsLastBaseBeforePosition}) );
        push @seqs, $left_seq;

        $current_seq = $current_seq->trunc($transposon->{TransposonCommentsFirstBaseAfterPosition} - $left_pos + 1, $current_seq->length);
        $current_seq->desc( join(' ', $transposon->{TransposonCommentsFirstBaseAfterPosition}, 'to', $self->seq->length) );
        $left_pos = $transposon->{TransposonCommentsFirstBaseAfterPosition};

    }

    # Nothing was excised
    return $current_seq if not @seqs;

    # Join @seqs into one...
    push @seqs, $current_seq;

    my $bases = join('', map { $_->seq } @seqs);
    my $transposon_excised_seq = Bio::Seq->new(
        -display_id => $self->project_name,
        -desc => join(' ', map { $_->desc } @seqs),
        -seq => $bases,
    );

    return $self->transposon_excised_seq($transposon_excised_seq);
}

1;

