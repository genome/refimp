package RefImp::Assembly::Submission;

use strict;
use warnings 'FATAL';

use LWP::UserAgent;
use XML::LibXML;

class RefImp::Assembly::Submission {
   doc => 'Assembly submission record',
   #data_source => RefImp::Config::get('ds_mysql'),
   #table_name => 'assemblies_submissions',
   id_generator => '-uuid',
   has => {
        biosample => { is => 'Text', },
   },
};

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    my $esummary = RefImp::Resources::Ncbi::EsummaryBiosample->create(biosample => $self->biosample);

    return $self;

    # TODO check agp/bases file(s)
    # if(defined($self->agp_file_path) && defined($self->contigs_bases_file_path)) {
    # TODO handle files ... need a submission dir?

    my $dom = $self->bioproject_biosample_xml_dom;
    my @links = $dom->findnodes('/eLinkResult/LinkSet/LinkSetDb/Link/Id');
    my $biosample_num = $self->biosample_id;
    $biosample_num =~ s/\D//g;

    unless( grep { $biosample_num == $_->textContent } @links ) {
        $self->fatal_message("BioProject ".$self->bioproject_id." is not linked with BioSample ".$self->biosample_id);
        return;
    }

    # ensure that the release date has been set
    unless ($self->release_date) {
        die "[err] A 'release date' has not been set on the ",
            "GSC::GenBankAssemblySubmission!\n";
    }

    return $self;
}

sub organism_name_and_strain {
    my $self = shift;
    $self->query_ncbi_xml_dom(qw/ Organism_Name Organism_Strain /);
}

1;
