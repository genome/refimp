package Pacbio::Run::SRAXML::PrimaryAnalysis;

use strict;
use warnings 'FATAL';

use Path::Class ('file','dir');
use Moose;
use Pacbio::Run::SRAXML::Experiment;
use Pacbio::Run::SRAXML::Run;
use Pacbio::Run::SRAXML::Submission;

extends 'Pacbio::Run::SRAXML';

has 'data' => (is => 'ro',required => 1,isa => 'ArrayRef');
has 'submission_alias'  => (is => 'ro',required => 1,isa => 'Str');

sub render_sra_xml {
    my $self = shift;
    my $data = $self->data;

    my $map = {Experiment => [],
             Run => []};
    for my $e (@{$data}) {
        my $run_data = delete $e->{run_data};
        push(@{$map->{Experiment}},$e);

        for my $r (@{$run_data}) {
            push(@{$map->{Run}},{alias => $r->{alias},
                           library_name => $e->{library_name},
                           file_type => $r->{file_type},
                           files => $r->{files}});
        }
    }

    my @xml;
    for my $target (sort keys %{$map}) {
        my $set = lc($target .'_set');
        my $class = 'Pacbio::Run::SRAXML::' .$target;
        my $struct = [map {$class->new($_)->data_struct} @{$map->{$target}} ];
        push(@xml,$self->struct_to_xml($set => {uc($target) => $struct} )) or return;
    }

    my $substruct = Pacbio::Run::SRAXML::Submission->new(alias => $self->submission_alias,
                                                         xml => [@xml],
                                                     )->data_struct;
    my $subxml = $self->struct_to_xml('submission_set' => $substruct) or return;

    return (@xml,$subxml);
}

1;
