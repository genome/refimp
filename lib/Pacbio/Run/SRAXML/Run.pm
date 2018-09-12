package Pacbio::Run::SRAXML::Run;

use strict;
use warnings 'FATAL';

use Path::Class ('file','dir');
use Moose;

has 'files'        => (is => 'ro',required => 1,isa => 'ArrayRef');
has 'alias'        => (is => 'ro',required => 1,isa => 'Str');
has 'library_name' => (is => 'ro',required => 1,isa => 'Str');
has 'checksum_method' => (is => 'ro',required => 1,isa => 'Str',default => 'MD5');

sub data_struct {
    my $self = shift;

    my $alias = $self->alias;
    my $file_block;
    for my $file (@{$self->files}) {
        push(@{$file_block},{'checksum' => $file->{checksum},
                             'filetype' => $file->{type},
                             'filename' => file($file->{file})->basename,
                             'checksum_method' => $self->checksum_method});
    }

    my $block = {
        alias => $alias,
        center_name => 'WUGSC',
        EXPERIMENT_REF => {
            refname   => $self->library_name,
            refcenter => 'WUGSC',
        },
        DATA_BLOCK => [
            {
                FILES =>
                    {
                        FILE => $file_block,
                    }
                }
        ],
    };
    return $block;
}

1;
