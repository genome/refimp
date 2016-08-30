package RefImp::Ace::Reader;

use strict;
use warnings;

sub new {
    my ($class, $input) = @_;

    die 'No input given to Ace Reader!' if not $input;

    my %self = (
        input => $input,
        object_builders => {
            AS => \&_build_assembly,
            AF => \&_build_read_position,
            CO => \&_build_contig,
            RD => \&_build_read,
            WA => \&_build_assembly_tag,
            CT => \&_build_contig_tag,
            RT => \&_build_read_tag,
            BS => \&_build_base_segment,
        },
    );

    bless \%self, $class;
}

sub next_object {
    my ($self) = @_;
    my $IN = $self->{input};
    my $ret_val;
    while (my $line = <$IN>) {
        chomp $line;
        if ($line =~ /^\s*$/) {
            next;
        }
        my @tokens = split(/[ {]/,$line);
        if (@tokens > 0) {
            my $type = shift @tokens;
            if (exists $self->{'object_builders'}->{$type}) {
                return $self->{'object_builders'}->{$type}->($self,$IN,\@tokens);
            }
        }
    }
    return undef;
}

sub next_object_of_type {
    my ($self, $type) = @_;
    while (my $obj = $self->next_object) {
        return $obj if $obj->{type} eq $type;
    }
    return;
}

sub _build_assembly {
    my ($self, $IN, $token_ary_ref) = @_;
    my %ret_val = (
        type => 'assembly',
        contig_count => $token_ary_ref->[0],
        read_count => $token_ary_ref->[1],
    );
    return \%ret_val;
}

sub _build_contig {
    my ($self, $IN, $token_ary_ref) = @_;
    my %ret_val = (
        type => 'contig',
        name => $token_ary_ref->[0],
        base_count => $token_ary_ref->[1],
        read_count => $token_ary_ref->[2],
        base_seg_count => $token_ary_ref->[3],
        u_or_c => $token_ary_ref->[4],
    );

    my $consensus;

    my $line;
    while ($line = <$IN>) {
        if ($line =~ /^\s*$/) {
            last;
        }
        chomp $line;
        $consensus .= $line;
    }
    $ret_val{'consensus'} = $consensus;
    while ($line = <$IN>) {
        if ($line =~ /^BQ/) {
            last;
        }
    }
    my @bq;
    while ($line = <$IN>) {
        if ($line =~ /^\s*$/) {
            last;
        }
        chomp $line;
        $line =~ s/^ //; # get rid of leading space
        push @bq, split(/ /,$line);
    }
    $ret_val{'base_qualities'} = \@bq;
    return \%ret_val;
}

sub _build_read_position {
    my ($self, $IN, $token_ary_ref) = @_;
    my %ret_val = (
        type => 'read_position',
        read_name => $token_ary_ref->[0],
        u_or_c => $token_ary_ref->[1],
        position => $token_ary_ref->[2],
    );
    return \%ret_val;
}

sub _build_base_segment {
    my ($self, $IN, $token_ary_ref) = @_;
    my %ret_val = (
        type => 'base_segment',
        start_pos => $token_ary_ref->[0],
        end_pos => $token_ary_ref->[1],
        read_name => $token_ary_ref->[2],
    );
    return \%ret_val;
}

sub _build_read {
    my ($self, $IN, $token_ary_ref) = @_;
    my %ret_val = (
        type => 'read',
        name => $token_ary_ref->[0],
        padded_base_count => $token_ary_ref->[1],
        info_count => $token_ary_ref->[2],
        tag_count => $token_ary_ref->[3],
    );
    my $sequence;
    my $line;
    while ($line = <$IN>) {
        if ($line =~ /^\s*$/) {
            last;
        }
        chomp $line;
        $sequence .= $line;
    }
    #my ($seq, $pads) = $self->un_pad_sequence($sequence);
    $ret_val{'sequence'} = $sequence;
    #$ret_val{'pads'} = $pads;
    while ($line = <$IN>) {
        chomp $line;
        if ($line =~ /^QA/) { my @tokens = split(/ /,$line); $ret_val{'qual_clip_start'} = $tokens[1]; $ret_val{'qual_clip_end'} = $tokens[2];
            $ret_val{'align_clip_start'} = $tokens[3];
            $ret_val{'align_clip_end'} = $tokens[4];
        }
        elsif ($line =~ /^DS/) {
            $line =~ s/ (\w+): /|$1|/g; #delimit the key-value pairs
            my @tokens = split(/\|/, $line); 
            shift @tokens; # drop the DS tag
            my %description = @tokens;
            $ret_val{'description'} = \%description;
            last;
        }
    }
    return \%ret_val;
}

sub _build_assembly_tag {
    my ($self, $IN, $token_ary_ref) = @_;
    my %ret_val;
    $ret_val{'type'} = 'assembly_tag';
    my $line = <$IN>;
    chomp $line;
	$line =~ s/^\s*// if $line =~ /\w/;;
    @ret_val{'tag_type', 'program', 'date'} = split(/ /, $line);
    my $data;
    while ($line = <$IN>) {
		$line =~ s/^\s*// if $line =~ /\w/;;
        if ($line =~ /^}/) {
            last;
        }
        $data .= $line;
    }
    $ret_val{'data'} = $data;

    return \%ret_val;
}

sub _build_contig_tag {
    my ($self, $IN, $token_ary_ref) = @_;
    my %ret_val;
    $ret_val{'type'} = 'contig_tag';
    my $line = <$IN>;
    chomp $line;
	$line =~ s/^\s*// if $line =~ /\w/;     
    @ret_val{'contig_name', 'tag_type', 'program', 'start_pos', 'end_pos', 'date', 'no_trans'} = split(/ /, $line);
    my $data = '';
    while ($line = <$IN>) {
		$line =~ s/^\s*// if $line =~ /\w/;
        if ($line =~ /^}/) {
            last;
        }
        $data .= $line;
    }
    $ret_val{'data'} = $data;

    return \%ret_val;
}

sub _build_read_tag {
    my ($self, $IN, $token_ary_ref) = @_;
    my %ret_val;
    $ret_val{'type'} = 'read_tag';
    my $line = <$IN>;
    chomp $line;
	$line =~ s/^\s*// if $line =~ /\w/;;
    @ret_val{'read_name', 'tag_type', 'program', 'start_pos', 'end_pos', 'date'} = split(/ /, $line);
    
    while (my $nextline= <$IN>)
    {
        last if $nextline=~/^\s*}\s*\n?$/;
        $ret_val{data}.=$nextline;
    }
    return \%ret_val;
}

1;

=pod

=head1 NAME

RefImp::Ace::Reader

=head1 SYNOPSIS

    my $reader = RefImp::Ace::Reader->new($handle);
    while (my $obj = $reader->next_object()) {
        if ($obj->{'type'} eq 'contig') {
            ...
        }
        ...
    }

=head1 DESCRIPTION

Iterates over an ace file, returning one element at a time.

=head1 METHODS

=item new [contructor] 

    my $reader = RefImp::Ace::Reader->new(input => \*STDIN);

=item next_object 

    my $obj_hashref = $reader->next_object();

    $obj_hashref->{'type'} eq 'contig'

    next_object returns the next object found in the ace file.  The return value is a
    hashref containing a 'type' key, and various other keys depending on the type:

    type eq 'assembly'
        contig_count
        read_count

    type eq 'contig'
        name
        base_count
        read_count
        base_seg_count
        u_or_c
        consensus
        base_qualities

    type eq 'read_position'
        read_name
        u_or_c
        position

    type eq 'base_segment'
        start_pos
        end_pos
        read_name

    type eq 'read'
        name
        padded_base_count
        info_count
        tag_count
        sequence
        qual_clip_start
        qual_clip_end
        align_clip_start
        align_clip_end
        description        - A hashref containing details about the trace
            CHROMAT_FILE
            PHD_FILE
            TIME

    type eq 'assembly_tag'
        tag_type
        program
        date
        data

    type eq 'contig_tag'
        contig_name
        tag_type
        program
        start_pos
        end_pos
        date
        no_trans
        data

    type eq 'read_tag'
        read_name
        tag_type
        program
        start_pos
        end_pos    
        date
        data

=cut
