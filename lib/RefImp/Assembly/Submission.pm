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
        bioproject => { is => 'Text', },
   },
};

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    return $self;

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

    # TODO handle files ... need a submission dir?
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

sub ncbi_xml_dom {
    my $self = shift;

    my $url = sprintf(
        'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?dbfrom=bioproject&db=biosample&id=%s',
        $self->bioproject,
    );

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->get($url);
    if ( not $response->is_success ) {
        $self->fatal_message('Failed to GET %s', $url);
    }

    my $dom  = XML::LibXML->load_xml(string => $response->decoded_content);
    my $error = $dom->findvalue('//error');
    $self->fatal_message("NCBI XML DOM error: $error") if $error;
    $dom;
}

sub query_ncbi_xml_dom {
    my ($self, @fields) = @_;
    $self->fatal_message('No fields given to retrieve from NCBI XML DOM!') if not @fields;

    my $dom = $self->ncbi_xml_dom;
    my $attrs = { map { my $v = $dom->findvalue("//$_") || undef; $_ => $v } @fields };
    $attrs;
}

sub organism_name_and_strain {
    my $self = shift;
    $self->query_ncbi_xml_dom(qw/ Organism_Name Organism_Strain /);
}

1;
