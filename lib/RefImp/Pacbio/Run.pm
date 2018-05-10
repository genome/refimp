package RefImp::Pacbio::Run;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
RefImp::Pacbio::Run->mk_accessors(qw/ directory /);

use Data::Dumper 'Dumper';
use File::Find;
use Path::Class;
use RefImp::Pacbio::RunMetadataFactory;

sub new {
    my ($class, $directory) = @_;

    die "No directory given!" if not $directory;
    die "Directory given does not exist: $directory" if not -d "$directory";

    my %self = (
        directory => $directory,
    );

    bless \%self, $class;
}

sub analyses_for_sample {
    my ($self, $sample_name_regex) = @_;
    die "No sample name regex given!" if not $sample_name_regex;

    my $analyses = $self->analyses;
    my @sample_analyses;
    for my $analysis ( @$analyses ) {
        push @sample_analyses, $analysis if $analysis->sample_name =~ $sample_name_regex;
    }

    return if not @sample_analyses;
    \@sample_analyses;
}

sub analyses {
    my ($self) = @_;

    my (@analyses, $meta);
    find(
        {
            wanted => sub{
                if ( /metadata\.xml$/) {
                    $meta = RefImp::Pacbio::RunMetadataFactory->build( file($File::Find::name) );
                    push @analyses, $meta;
                }
                elsif ( $File::Find::dir =~ /Analysis_Results/ and /\.h5$/ ) {
                    die "No meta set!" if not $meta;
                    $meta->add_analysis_file( file($File::Find::name) );
                }
            },
        },
        glob($self->directory->file('*')->stringify),
    );

    return if not @analyses;
    \@analyses;
}

1;
