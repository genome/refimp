package GetSeq;

use strict;
use warnings;
use Carp;

use IO::String;
use Bio::Seq;
use Bio::SeqIO;
use File::Basename;
use GSC::IO::Assembly::Ace;
use ProjectWorkBench::Model::Ace::Dir;
use RefImp::Clone::Submissions;

sub new {
    my ($class, %params) = @_;
    
    croak "Give both type and name option\n" 
	unless $params{type} and $params{name};

    croak "type should be one of ace, project, fasta or item\n"
	unless $params{type} =~ /^(ace|project|fasta|item)$/;

    my $self = \%params;
    bless $self, $class;

    $self->_setup;

    return $self;
}


sub _setup {
    my $self = shift;
    my $type = $self->{type};

    if ($type eq 'ace') {
	$self->_get_seq_from_ace($self->{name});
    }
    elsif ($type eq 'fasta') {
	$self->_get_seq_from_fasta;
    }
    elsif ($type eq 'project') {
	$self->_get_seq_from_project;
    }
    elsif ($type eq 'item') {
	$self->_get_seq_from_item;
    }
    else {
	croak "Invalid type, must be ace, fasta, project or item\n";
    }
    
    $self->_trim_seq if $self->{end_cut} or $self->{size_limit};

    return;
}


sub _get_seq_from_ace {
    my ($self, $acefile) = @_;
    croak "acefile $acefile doesn't exist\n" unless -s $acefile;
    
    my $test = `head -1 $acefile`;
    croak "$acefile is not a valid ace file\n" unless $test =~ /^AS\s/;

    my $ace_object = GSC::IO::Assembly::Ace->new(input_file => $acefile);
    croak "No AceObject for $acefile\n" unless $ace_object;
    
    my $prefix = $self->{prefix};
    my ($name) = basename $acefile =~ /^(\S+?)\./;
    $prefix = $prefix ? "$name." : '';

    my %ctg_pad_seqs = $ace_object->contig_names_and_padded_seqs();
    my @seqs = ();

    for my $ctg_name (sort{($a=~/Contig(\S+)/)[0] <=> ($b=~/Contig(\S+)/)[0]}keys %ctg_pad_seqs) {
	my $seq = $ctg_pad_seqs{$ctg_name}; 
	$seq =~ s/\*//g; 
	$seq =~ s/x/n/gi;
	push @seqs, Bio::Seq->new(-seq => $seq, -id => $prefix.$ctg_name);
    }

    $self->{seqs} = \@seqs;
    return;
}


sub _get_seq_from_fasta {
    my $self = shift;
    
    my $name = $self->{name};
    croak "fasta $name doesn't exist\n" unless -s $name;

    my $test = `head -1 $name`;
    croak "fasta $name is not a valid fasta file\n" unless $test =~ /^>/;

    $self->_get_bio_seqs($name);
    return;
}


sub _get_seq_from_project {
    my $self = shift;
    my $name = $self->{name};

    my $clone  = RefImp::Clone->get(name => $name);
    if ($self->{finished}) {
	croak "clone $name is not in DB\n" unless $clone;
	$self->_get_finished_seq($clone);
    }
    else {
	my $proj_dir = $clone->project_directory;

	if ($proj_dir and -d $proj_dir) {
	    my $ace = ProjectWorkBench::Model::Ace::Dir->new(dir => $proj_dir.'/edit_dir');
	    croak "No Ace Dir obj for this dir\n" unless $ace;
	
	    my $recent_ace = $ace->recent_acefile;
	    croak "No recent ace for this AceDir obj or it's empty\n" 
		unless $recent_ace and -s $recent_ace;
  
	    $self->_get_seq_from_ace($recent_ace);
	}
	else {
	    print "Can't locate clone $name. Now try get its finished seq\n";
	    $self->_get_finished_seq($clone);
	}
    }
    return;
}


sub _get_seq_from_item {
    my $self = shift;
    my $name = $self->{name};
    
    my $item = GSC::Sequence::Item->get(sequence_item_name => $name);
    croak "sequence item $name doesn't have item obj\n" unless $item;

    $self->{seqs} = [$item->get_seq_with_quality];
    return;
}


sub _get_finished_seq {
    my ($self, $clone) = @_;

    my $name = $clone->name;

    my $clone_analysis_dir = RefImp::Clone::Submissions->analysis_directory_for_clone($clone);
    croak "can't locate analysis finished seqs for $name\n" unless $clone_analysis_dir;

    my @submit_dirs = sort { $b cmp $a } glob( File::Spec->join($clone_analysis_dir, '20*') );
    croak "can't figure out finished seq dir for $name\n" unless @submit_dirs;
    
    my ($seq_file) = $self->{whole} 
                   ? glob( File::Spec->join($submit_dirs[0], "*.whole.contig") )
                   : glob( File::Spec->join($submit_dirs[0], "$name.*seq") );

    croak "can't locate finished .whole.contig or .seq file for $name\n" 
	unless $seq_file and -s $seq_file;

    $self->_get_bio_seqs($seq_file);
    return;
}


sub _trim_seq {
    my $self = shift;
    my @seqs = ();

    my $end_cut    = $self->{end_cut}    if $self->{end_cut};
    my $size_limit = $self->{size_limit} if $self->{size_limit};

    if ($end_cut) {
	for my $seq (@{$self->get_seq}) {
	    my $length  = $seq->length;
	    my $realcut = ($length > $end_cut) ? $end_cut : $length;

	    if ($size_limit) {
		next unless $length > $size_limit;
	    }
	    
	    my $subseq_left  = $seq->trunc(1, $realcut);
	    $subseq_left ->display_id($seq->display_id.'.left');
	    my $subseq_right = $seq->trunc($length-$realcut+1, $length);
	    $subseq_right->display_id($seq->display_id.'.right');
	    
	    push @seqs, $subseq_left, $subseq_right;
	}
    }
    elsif ($size_limit) {
	for my $seq (@{$self->get_seq}) {
	    push @seqs, $seq if $seq->length > $size_limit;
	}
    }

    $self->{seqs} = \@seqs;
    return;
}


sub _get_bio_seqs {
    my ($self, $name) = @_;
    my @seqs = ();

    my $io = Bio::SeqIO->new(-format => 'Fasta', -file => $name);

    while (my $seq = $io->next_seq) {
	push @seqs, $seq;
    }

    $self->{seqs} = \@seqs;
    return;
}


sub get_seq {
    return shift->{seqs};
}


sub get_string {
    my $self   = shift;
    my $io     = IO::String->new();
    my $writer = Bio::SeqIO->new('-fh' => $io, '-format' => 'fasta');

    $writer->write_seq(@{$self->get_seq});
    $io->seek(0, 0);

    return join '', $io->getlines;
}


sub get_file {
    my ($self, $name) = @_;
    $name = '/tmp/GetSeq_'.basename($self->{name})."_$$" unless $name;

    my $out = Bio::SeqIO->new(-file => ">$name", -format => 'Fasta');
    $out->write_seq(@{$self->get_seq});

    chmod 0664, $name;
    return $name;
}


=pod

=head1 Name

GetSeq

> get Bio::Seq objects from ace file, GSC project, GSC sequence item with option to trim

=head1 Description

take type, name, prefix, end_cut, size_limit, finished, whole as options

type and name options are required. type must be one of ace, fasta, project or item.
name must be valid GSC project/item name or fasta/acefile name with path. If project
is given as option, its most recent acefile will be used to get seq. If project is 
finished and offline, finished project sequences will be retrieved from analysis. 
Currently, the item can only be either contig or read, not supercontig or assembly.

prefix is the prefix of the fasta header. If it is true (1), an acefile header or 
project name will be added in front of contig name as fasta header.

If size_limit provided, the Bio::Seq seq whose length is smaller than this value
will be filtered out. If end_cut provided, the sequence of this bp value off both
ends will be used. 

finished will retrieve finished project sequence from analysis. whole will retrieve
only .whole.contig as sequence, not .seq (as default for finished). Here .whole means
the whole main contig, while .seq means the finished region of the main contig. They
are not always same. 

=head1 Synopsis

=head2 new

$seq = GetSeq->new(
    type       => 'ace',
    name       => '/gscuser/seqmgr/PMLRAR/edit_dir/PMLRAR.fasta.screen.ace',
    prefix     => 1,
    end_cut    => 2000,
    size_limit => 2000,
);


=head2 get_seq

map{print $_->length."\n"}@{$seq->get_seq};

=head2 get_string

$seq_string = $seq->get_string;

=head2 get_file

$file = $seq->get_file("/gscuser/fdu/test.fasta");

=head1 Author

Feiyu Du <fdu@watson.wustl.edu>

=cut

1;

#$HeadURL: svn+ssh://svn/srv/svn/gscpan/perl_modules/trunk/GetSeq.pm $
#$Id: GetSeq.pm 33164 2008-03-24 16:36:46Z fdu $

