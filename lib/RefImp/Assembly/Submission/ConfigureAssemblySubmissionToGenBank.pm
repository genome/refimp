package GSC::PSE::ConfigureAssemblySubmissionToGenBank;
use strict;
use warnings FATAL => qw(all);
use Moose;

sub file_sets { return shift->added_param('file_sets'); }
sub parsed_file_sets {
    my $self=shift;

    my @file_sets;
    foreach my $fileset_string ($self->file_sets) {
        my ($agp, $contig)=split(/:/,$fileset_string);
        push @file_sets, {
                          agp_file_path           => $agp,
                          contigs_bases_file_path => $contig,
                         }
    }

    return @file_sets;
}

sub agp_file_path { return ( shift->added_param('agp_file_path') )[0]; }
sub authors_json  { return ( shift->added_param('authors_json') )[0]; }
sub bioproject_id { return ( shift->added_param('bioproject') )[0]; }
sub biosample_id { return ( shift->added_param('biosample') )[0]; }

sub contigs_bases_file_path {
    return ( shift->added_param('contigs_bases_file_path') )[0];
}

sub genome_model_build_id {
    return ( shift->added_param('genome_model_build_id') )[0];
}

sub minimum_contig_length {
    return ( shift->added_param('minimum_contig_length') )[0];
}
sub version { return ( shift->added_param('version') )[0]; }

sub unstructured_comment { return ( shift->added_param('unstructured_comment') )[0]; }

sub assembly_method { return ( shift->added_param('assembly_method') )[0]; }
sub genome_coverage { return ( shift->added_param('genome_coverage') )[0]; }
sub sequencing_technology { return ( shift->added_param('sequencing_technology') )[0]; }
sub tbl2asn_source_qualifiers { return ( shift->added_param('tbl2asn_source_qualifiers') )[0]; }
sub email_ncbi { return ( shift->added_param('email_ncbi') )[0]; }
sub release_date { return ( shift->added_param('release_date') )[0]; }

sub get_genbank_assembly_submission {
    my $self = shift;
    return GSC::GenBankAssemblySubmission->get(
        creation_event_id => $self->id );
}

sub confirmable_control_pse_id { 1 }

sub confirmable {
    my $self = shift;
    return unless $self->SUPER::confirmable(@_);

    my @file_sets=$self->file_sets;
    if(! @file_sets && !($self->agp_file_path && $self->contigs_bases_file_path)) {
        $self->error_message('no file_sets nor agp/contigs_bases file_paths found');
        return;
    }

    my $dom = XML::LibXML->load_xml(
        string => &get_bioproject_biosample_link_xml($self->bioproject_id) );
    my @links = $dom->findnodes('/eLinkResult/LinkSet/LinkSetDb/Link/Id');
    my $biosample_num = $self->biosample_id;
    $DB::single=1;
    $biosample_num =~ s/\D//g; # replace non-digits with nothing

    unless( grep { $biosample_num == $_->textContent } @links )
    {
        $self->error_message("BioProject ".$self->bioproject_id." is not linked with BioSample ".$self->biosample_id);
        return;
    }
    return 1;
};

sub get_bioproject_biosample_link_xml {
    my $project = shift;
    my $usera = LWP::UserAgent->new;
    $usera->timeout(10);
    $usera->env_proxy;

    my $request_uri = 'https://eutils.ncbi.nlm.nih.gov'
        .'/entrez/eutils/elink.fcgi?dbfrom=bioproject&db=biosample&id='
        . $project;

    my $esummary_response = $usera->get($request_uri);
    $esummary_response = $usera->get($request_uri)
        unless $esummary_response->is_success;
    return unless $esummary_response->is_success;

    return $esummary_response->decoded_content;
}

sub confirm {
    my $self = shift;
    return unless $self->SUPER::confirm;

    my $gb   = GSC::GenBankAssemblySubmission->create(
        creation_event_id => $self->id,
        last_event_id     => $self->id,
        status            => 'configured',

        (map {$_ => $self->$_} grep {defined $self->$_} qw(
        authors_json
        bioproject_id
        biosample_id
        genome_model_build_id
        minimum_contig_length
        version
        unstructured_comment
        assembly_method
        genome_coverage
        sequencing_technology
        tbl2asn_source_qualifiers
        email_ncbi
        release_date)),
    );

    if(defined($self->agp_file_path) && defined($self->contigs_bases_file_path)) {
        my $gbsf=GSC::GenBankSubFileset->create(
                                                gas_id                  => $gb,
                                                agp_file_path           => $self->agp_file_path,
                                                contigs_bases_file_path => $self->contigs_bases_file_path
                                               );
        die 'Could not create fileset' unless($gbsf);
    }

    foreach my $fileset ($self->parsed_file_sets) {
        my $gbsf=GSC::GenBankSubFileset->create(
                                                gas_id                  => $gb,
                                                agp_file_path           => $fileset->{agp_file_path},
                                                contigs_bases_file_path => $fileset->{contigs_bases_file_path},
                                               );
        die 'Could not create fileset' unless($gbsf);
    }

    # ensure that the email_ncbi flag has been set
    unless ($gb->email_ncbi == 1 || $gb->email_ncbi == 0) {
        die "[err] Cannot ascertain if we should email NCBI ",
            "about the assembly submission!\n";
    }

    # ensure that the release date has been set
    unless ($gb->release_date) {
        die "[err] A 'release date' has not been set on the ",
            "GSC::GenBankAssemblySubmission!\n";
    }

    return unless $gb;
    return 1;
}

sub expunge_execution {
    my $self = shift;
    my $gas = $self->get_genbank_assembly_submission;
    if ($gas->delete) {
        return 1;
    }
    else {
        return;
    }
}

1;
