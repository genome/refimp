package RefImp::Assembly::Submission;

use strict;
use warnings 'FATAL';

use LWP::UserAgent;
use XML::LibXML;

class RefImp::Assembly::Submission {
    has_optional => {
        agp_file_path => { is => 'Text', },
        assembly_method => { is => 'Text', },
        authors_json  => { is => 'Text', },
        bioproject_id => { is => 'Text', },
        biosample_id => { is => 'Text', },
        contigs_bases_file_path => { is => 'Text', },
        file_sets => { is => 'Text', },
        genome_model_build_id => { is => 'Text', },
        genome_coverage => { is => 'Text', },
        minimum_contig_length => { is => 'Text', },
        release_date => { is => 'Text', },
        sequencing_technology => { is => 'Text', },
        tbl2asn_source_qualifiers => { is => 'Text', },
        unstructured_comment => { is => 'Text', },
        version => { is => 'Text', },
   },
};

sub bioproject_biosample_xml_dom {
    my $self = shift;

    my $url = sprintf(
        'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=bioproject&db=biosample&id=%s', $self->bioproject,
    );

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->get($url);
    #$response = $ua->get($request_uri) unless $esummary_response->is_success; # retry?
    if ( not $response->is_success ) {
        $self->fatal_message('Failed to GET %s', $url);
    }

    XML::LibXML->load_xml(string => $response->decoded_content);
}

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    my @file_sets=$self->file_sets;
    if(! @file_sets && !($self->agp_file_path && $self->contigs_bases_file_path)) {
        $self->error_message('no file_sets nor agp/contigs_bases file_paths found');
        return;
    }

    my $dom = $self->bioproject_biosample_xml_dom;
    my @links = $dom->findnodes('/eLinkResult/LinkSet/LinkSetDb/Link/Id');
    my $biosample_num = $self->biosample_id;
    $biosample_num =~ s/\D//g;

    unless( grep { $biosample_num == $_->textContent } @links ) {
        $self->fatal_message("BioProject ".$self->bioproject_id." is not linked with BioSample ".$self->biosample_id);
        return;
    }

    if(defined($self->agp_file_path) && defined($self->contigs_bases_file_path)) {
    # my $gbsf=GSC::GenBankSubFileset->create( gas_id                  => $gb, agp_file_path           => $self->agp_file_path, contigs_bases_file_path => $self->contigs_bases_file_path);
    }

    my @file_sets;
    foreach my $fileset_string ($self->file_sets) {
        my ($agp, $contig)=split(/:/,$fileset_string);
        push @file_sets, {
                          agp_file_path           => $agp,
                          contigs_bases_file_path => $contig,
                         }
    }
    foreach my $fileset (@file_sets) {
    #my $gbsf=GSC::GenBankSubFileset->create( gas_id                  => $gb, agp_file_path           => $fileset->{agp_file_path}, contigs_bases_file_path => $fileset->{contigs_bases_file_path},);
    }

    # ensure that the release date has been set
    unless ($self->release_date) {
        die "[err] A 'release date' has not been set on the ",
            "GSC::GenBankAssemblySubmission!\n";
    }

    return $self;
}

1;
