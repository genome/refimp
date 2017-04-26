package RefImp::Assembly::Submission;

use strict;
use warnings 'FATAL';

class RefImp::Assembly::Submission {
   doc => 'Assembly submission record',
   #data_source => RefImp::Config::get('ds_mysql'),
   #table_name => 'assemblies_submissions',
   id_generator => '-uuid',
   has => {
    # assembler => on asssembly
    # read_type => on assembly
        agp_file => { is => 'Text', doc => 'AGP file', },
        authors => { is => 'Text', doc => 'Comma separated list of authors', },
        biosample => { is => 'Text', doc => 'NCBI biosample', },
        bioproject => { is => 'Text', doc => 'NCBI bioproject', },
        contigs_file => { is => 'Text', doc => 'Contigs [bases] fasta file', },
        coverage => { is => 'Text', doc => 'Coverage', },
        release_date => { is => 'Date', doc => '', },
        supercontigs_file => { is => 'Text', doc => 'Supercontigs fasta file', },
        version => { is => 'Text', doc => 'NCBI formatted assembly version', },
   },
   has_optional_transient => {
        esummary => { is => 'RefImp::Resources::Ncbi::EsummaryBiosample', },
   },
};

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    my $esummary = RefImp::Resources::Ncbi::EsummaryBiosample->create(biosample => $self->biosample);
    $self->fatal_message('Bioproject given does not match that found linked to biosample! %s <=> %s', $self->bioproject, $esummary->bioproject) if $self->bioproject ne $esummary->bioproject;
    $self->esummary($esummary);

    # TODO
    # check contigs/supercontigs/agp file(s)
    # check contigs/supercontigs names are in agp
    # check RELEASE_NOTES and FINAL_STATS files
    # export as yml with assembly info

    $self;
}

1;
