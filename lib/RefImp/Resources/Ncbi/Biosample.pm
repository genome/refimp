package RefImp::Resources::Ncbi::Biosample;

use strict;
use warnings 'FATAL';

use LWP::UserAgent;
use XML::LibXML;

class RefImp::Resources::Ncbi::Biosample {
    has => {
        biosample => { is => 'Text', },
    },
    has_calculated => {
        biosample_uid => {
            is => 'Text',
            calculate_from =>[qw/ biosample /],
            calculate => q| $biosample =~ s/\D//g; $biosample =~ s/^0+//; $biosample; |,
        },
    },
    has_optional_transient => {
        bioproject => { is => 'Text', },
        bioproject_uid => { is => 'Text', },
        project_title => { is => 'Text', },
        xml_content => { is => 'Text', },
    },
    doc => 'NCBI E-Utils Biosample Helper',
};

sub esummary_url {
    sprintf(
        'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?dbfrom=bioproject&db=biosample&id=%s',
        $_[0]->biosample_uid,
    );
}

sub create {
    my $class = shift;
    
    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->__init__;
}

sub __init__ {
    my $self = shift;

    $self->fatal_message('No biosample given!') if not $self->biosample;
    $self->load_xml_dom;
    $self;
}

sub fetch_xml_content {
    my $self = shift;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $url = $self->esummary_url;
    my $response = $ua->get($url);
    if ( not $response->is_success ) {
        $self->fatal_message('Failed to GET %s', $url);
    }

    $self->xml_content( $response->decoded_content );
}

sub load_xml_dom {
    my $self = shift;

    my $dom  = XML::LibXML->load_xml(string => $self->fetch_xml_content);
    my $error = $dom->findvalue('//error');
    $self->fatal_message("NCBI XML DOM error: $error") if $error;

    my $title = $dom->findvalue("//Title");
    $self->fatal_message("No project title in esummary biosample XML!\n%s", $self->xml_content) if not $title;
    $self->project_title($title);

    my $sample_data = $dom->findvalue("//SampleData");
    $self->fatal_message('No sample data xml') if not $sample_data;

    my $biosample_dom = XML::LibXML->load_xml(string => $sample_data);
    my $error = $biosample_dom->findvalue('//error');
    $self->fatal_message("Biosample XML DOM error: $error") if $error;

    my $bioproject = $biosample_dom->findvalue('/BioSample/Links/Link/@label');
    $self->bioproject($bioproject);
    my $bioproject_uid = $biosample_dom->findvalue('/BioSample/Links/Link');
    $self->bioproject_uid($bioproject_uid);
}

1;
