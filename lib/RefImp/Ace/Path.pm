package RefImp::Ace::Dir;

use strict;
use warnings;

use Carp;
use File::Basename;

sub new {
    my $class = shift;
    
    my %p = @_;
    
    my $self = bless \%p, $class;

    confess "Invalid dir\n" unless -d $self->dir;
    
    return $self;
}

sub dir {
    my $self = shift;

    return $self->{dir};
}

sub acefile_for_ace {
    my ($self, $ace) = @_;

    return $self->dir . "/$ace";
}

sub all_acefiles {
    my $self = shift;
    
    my $acedir = $self->dir;

#   return grep{`head -1 $_` =~ /^AS\s/}split/\n/, `ls -t $acedir/*.ace*`;

    my @files = glob( "$acedir/*ace*" );
    my @valid_acefiles;
    for my $file ( @files ) {
	next if -d $file; #exclude *ace.idx dirs
	next unless grep {`head -1 $_` =~ /^AS\s/} $file; #exclude none ace *ace* files
	push @valid_acefiles, $file;
    }
    @valid_acefiles = sort { -M $a <=> -M $b } @valid_acefiles; #sort by time

    return @valid_acefiles;
}

sub all_aces {
    my $self = shift;
    
    return map { basename($_) } $self->all_acefiles;
}

sub acefiles {
    my $self = shift;
    
    return grep { $_ !~ /mini|wrk|view|WAITING|fasta$|log|status|nav|fof|dat|phrap\.out/} $self->all_acefiles;
}

sub aces {
    my $self = shift;
    
    return map { basename($_) } $self->acefiles;
}

sub recent_ace {
    my $self = shift;

    my @aces = $self->aces;

    return shift @aces;
}

sub recent_acefile {
    my $self = shift;

    my @acefiles = $self->acefiles;

    return shift @acefiles;
}

sub date_for_ace {
    my ($self, $ace) = @_;
    
    my $acefile = $self->acefile_for_ace($ace);
    
    my $time = `/bin/ls -lt $acefile | awk \'{print \$6,\$7,\$8}\'`;
    chomp $time;

    return $time;
}

sub age_for_ace {
    my ($self, $ace) = @_;

    return sprintf("%d", -M $self->acefile_for_ace($ace));
}

sub owner_for_ace {
    my ($self, $ace) = @_;
    
    my $acefile = $self->acefile_for_ace($ace);

    my $owner = `/bin/ls -lt $acefile | awk \'{print \$3}\'`;
    chomp $owner;
    
    return $owner;
}

1;

=pod

=head1 Name

ProjectWorkBench::Model::Ace::Dir

 > Object

=head1 Methods

=head2 new

 my $acedir = ProjectWorkBench::Model::Ace::Dir->new(dir => $acedir);

 > Constructor, needs to be passed a valid directory
 
=head2 dir

 my $dir = $acedir->dir;

 > Gets the directory
 
=head2 acefile_for_ace

 my $acefile = $acedir->acefile_for_ace($ace);

 > returns the full path of an ace
 
=head2 all_acefiles

 my @acefiles = $acedir->all_acefiles;

 > Returns all files in dir matching *ace*
 
=head2 all_aces
 
 my @aces = $acedir->all_aces;

 > Returns basenames for all files in dir matching *ace*

=head2 acefiles

 my @acefiles = $acedir->acefiles;

 > Returns files in dir matching *ace*, but exluding probable non aces matching these patterns:
    /mini|wrk|view|WAITING|fasta$|log|status|nav|fof|dat/ 

=head2 aces

 my @aces = $acedir->aces;

 > Returns basenames of files in dir matching *ace*, but exluding probable non aces matching these patterns:
    /mini|wrk|view|WAITING|fasta$|log|status|nav|fof|dat/ 

=head2 recent_ace

 my $ace = $acedir->recent_ace

 > Returns the basename of the most recent acefile, not matching these patterns:
    /mini|wrk|view|WAITING|fasta$|log|status|nav|fof|dat/ 
 
=head2 recent_acefile

 my $acefile = $acedir->recent_acefile

 > Returns the most recent acefile (full path), not matching these patterns:
    /mini|wrk|view|WAITING|fasta$|log|status|nav|fof|dat/ 
    
=head2 date_for_ace

 my $date = $acedir->date_for_ace($ace);

 > Returns the $date stamp of $ace

=head2 age_for_ace

 my $age = $acedir->age_for_ace($ace);

 > Returns the $age in days of $ace
 
=head2 owner_for_ace

 my $owner = $acedir->owner_for_ace($ace);

 > Returns the owner of $ace

=head1 Disclaimer

 Copyright (C) 2006-2007 Washington University Genome Sequencing Center

 This module is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY or the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
 License for more details.

=head1 Author(s)

 Eddie Belter <ebelter@watson.wustl.edu>

=cut

#$HeadURL: svn+ssh://svn/srv/svn/gscpan/perl_modules/trunk/ProjectWorkBench/Model/Ace/Dir.pm $
#$Id: Dir.pm 63476 2011-02-01 17:44:25Z kkyung $
