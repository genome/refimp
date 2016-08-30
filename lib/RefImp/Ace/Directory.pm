package RefImp::Ace::Directory;

use strict;
use warnings;

use Carp;
use IO::File;
use File::Basename;
use File::Spec;
use UR;

class RefImp::Ace::Directory {
    id_by => {
        path => { is => 'Path', },
    },
};

sub create {
    my ($class, %params) = @_;
    
    $class->fatal_message("No path given to %s!", $class) if not $params{path};

    my $self = $class->SUPER::create(%params);
    return if not $self;

    $self->fatal_message("Path does not exist! ", $self->path) if not -d $self->path;
    
    return $self;
}

sub acefiles {
    my $self = shift;
    
    my $acedir = $self->path;

    my @files = glob( File::Spec->join($self->path, '*.ace*') );
    my @valid_acefiles;
    for my $file ( @files ) {
        next if -d $file; #exclude *ace.idx dirs
        my $fh = IO::File->new($file);
        my $line = $fh->getline;
        $fh->close;
        next unless $line =~ /^AS\s/;
        push @valid_acefiles, $file;
    }

    return sort { -M $a <=> -M $b } @valid_acefiles; #sort by time
}
sub aces { map { File::Basename::basename($_) } $_[0]->acefiles; }
sub acefile_for_ace { File::Spec->join($_[0]->path, $_[1]); }

sub recent_ace {
    my $acefile = $_[0]->recent_acefile || return;
    File::Basename::basename($acefile);
}
sub recent_acefile { ($_[0]->acefiles)[0] } 

1;

=pod

=head1 Name

RefImp::Ace::Directory

=head1 Methods

=head2 create

 my $acedir = RefImp::Ace::Directory->create(path => $edit_dir);

 > Constructor. Valid path is required.

=head2 create

 my $acedir = RefImp::Ace::Directory->get(path => $edit_dir);

 > Get from cache by path [id].

=head2 dir

 my $dir = $acedir->path;

 > Accessor to get the path.

=head2 acefile_for_ace

 my $acefile = $acedir->acefile_for_ace($ace);

 > returns the full path of an ace

=head2 acefiles

 my @acefiles = $acedir->acefiles;

 > Returns all ace files in path matching *.ace* and the have an ace header [AS \d \d].

=head2 aces

 my @aces = $acedir->aces;

 > Returns basenames for all the ace files in path.

=head2 recent_ace

 my $ace = $acedir->recent_ace

 > Returns the basename of the most recent acefile.

=head2 recent_acefile

 my $acefile = $acedir->recent_acefile

 > Returns the most recent ace file (full path).

=cut
