package RefImp::Pacbio::Run;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
RefImp::Pacbio::Run->mk_accessors(qw/ directory /);

use Data::Dumper 'Dumper';
use File::Find;
use Path::Class;
use RefImp::Pacbio::RunMetadata;

sub new {
    my ($class, $directory) = @_;

    die "No directory given!" if not $directory;
    die "Directory given does not exist: $directory" if not -d "$directory";

    my %self = (
        directory => $directory,
    );

    bless \%self, $class;
}

sub analysis_files_for_sample {
    my ($self, $sample_name_regex) = @_;
    die "No sample name regex given!" if not $sample_name_regex;

    my $files = $self->samples_and_analysis_files;

    my @sample_files;
    for my $sample_name ( sort keys %$files ) {
        push @sample_files, @{$files->{$sample_name}} if $sample_name =~ $sample_name_regex;
    }

    return if not @sample_files;
    \@sample_files;
}

sub samples_and_analysis_files {
    my ($self) = @_;

    my %samples_and_analysis_files;
    my ($well, $metadata, $sample_name);
    find(
        {
            wanted => sub{
                if ( /metadata\.xml$/) {
                    $metadata = RefImp::Pacbio::RunMetadata->new( file($File::Find::name) );
                    die "Failed load metadata XML for $_" if not $metadata;
                    $sample_name = $metadata->sample_name;
                    die "Failed to get sample name from run metadata XML: $_" if not $sample_name;
                }
                elsif ( $File::Find::dir =~ /Analysis_Results/ and /\.h5$/ ) {
                    die "No sample name set!" if not $sample_name;
                    push @{$samples_and_analysis_files{$sample_name}}, file($File::Find::name);
                }
            },
        },
        glob($self->directory->file('*')->stringify),
    );

    return if not %samples_and_analysis_files;
    \%samples_and_analysis_files;
}

1;
