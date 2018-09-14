package Pacbio::Run::SRAXML::Experiment;

use strict;
use warnings 'FATAL';

use Path::Class ('file','dir');

use Moose;
use Moose::Util::TypeConstraints;

subtype 'LibraryLayout', as 'Str', where {$_ eq 'single' || $_ eq 'paired'};

has 'library_name'      => (is => 'ro',required => 1,isa => 'Str');
has 'bioproject'        => (is => 'ro',required => 1,isa => 'Str');
has 'biosample'         => (is => 'ro',required => 1,isa => 'Str');
has 'instrument'        => (is => 'ro',required => 1,isa => 'Str');
has 'version'           => (is => 'ro',required => 1,isa => 'Str');
has 'library_layout'    => (is => 'ro',required => 1,isa => 'LibraryLayout');
has 'library_source'    => (is => 'ro',required => 0,isa => 'Str');
has 'library_selection' => (is => 'ro',required => 0,isa => 'Str');
has 'library_strategy'  => (is => 'ro',required => 0,isa => 'Str');
has 'size'              => (is => 'ro',required => 0,isa => 'Num');#(size and std dev in bp)
has 'size_sd'           => (is => 'ro',required => 0,isa => 'Num');

sub data_struct {
    my $self = shift;

    my $layout;
    if ($self->library_layout eq 'single') {
        $layout = {SINGLE => {} };
    }
    elsif (defined $self->size && defined $self->size_sd) {
        $layout = {PAIRED => {NOMINAL_LENGTH => $self->size, NOMINAL_SDEV => $self->size_sd}};
    }
    else {
        die "if layout (library type) is not single (paired), must supply size and sd";
    }

    my $struct = {
        alias => $self->library_name,
        center_name => 'WUGSC',
        TITLE => {title => $self->instrument .' Sequencing for ' .$self->library_name},
        STUDY_REF => {IDENTIFIERS => {EXTERNAL_ID => { namespace => 'BioProject',
                                                       _ => $self->bioproject}}},
                                                    # '_' represent the value of the tag EXTERNAL_ID
        DESIGN => {DESIGN_DESCRIPTION => '',
                   SAMPLE_DESCRIPTOR => {IDENTIFIERS => {EXTERNAL_ID => {namespace => 'BioSample',
                                                                         _ => $self->biosample}}},
                   LIBRARY_DESCRIPTOR => {
                       LIBRARY_NAME      => $self->library_name,
                       LIBRARY_STRATEGY  => $self->library_strategy ? $self->library_strategy : 'WGS',
                       LIBRARY_SOURCE    => $self->library_source ? $self->library_source : 'GENOMIC',
                       LIBRARY_SELECTION => $self->library_selection ? $self->library_selection : 'unspecified',
                       LIBRARY_LAYOUT    => $layout,
                   },
               },
        PLATFORM => {PACBIO_SMRT => {INSTRUMENT_MODEL => $self->instrument} },
        PROCESSING => {PIPELINE => {PIPE_SECTION => {STEP_INDEX => '',
                                                     PREV_STEP_INDEX => '',
                                                     PROGRAM => $self->instrument,
                                                     VERSION => $self->version,
                                                 } }},
    };
    return $struct;
}

1;
