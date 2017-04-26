package RefImp::Resources::Ncbi::EsummaryBiosample;

use strict;
use warnings 'FATAL';

use LWP::UserAgent;
use XML::LibXML;

class RefImp::Resources::Ncbi::EsummaryBiosample {
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
        dom => { is => 'XML::LibXML::Document', },
        bioproject => { is => 'Text', },
        bioproject_uid => { is => 'Text', },
    },
    doc => 'NCBI E-Utils Biosample Helper',
};

sub eutils_biosample_url {
    sprintf(
        'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?dbfrom=bioproject&db=biosample&id=%s',
        $_[0]->biosample_uid,
    );
}

sub create {
    my $class = shift;
    
    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->fatal_message('No biosample given!') if not $self->biosample;
    $self->load_xml_dom;

    $self;
}

sub load_xml_dom {
    my $self = shift;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $url = $self->eutils_biosample_url;
    my $response = $ua->get($url);
    if ( not $response->is_success ) {
        $self->fatal_message('Failed to GET %s', $url);
    }

    my $dom  = XML::LibXML->load_xml(string => $response->decoded_content);
    my $error = $dom->findvalue('//error');
    $self->fatal_message("NCBI XML DOM error: $error") if $error;
    $self->dom($dom);

    $self->_load_biosample_xml_dom;
}

sub _load_biosample_xml_dom {
    my $self = shift;

    my $attrs = $self->query_dom('SampleData');
    $self->fatal_message('No sample data xml') if not $attrs->{SampleData};

    my $biosample_dom = XML::LibXML->load_xml(string => $attrs->{SampleData});
    my $error = $biosample_dom->findvalue('//error');
    $self->fatal_message("Biosample XML DOM error: $error") if $error;

    my $bioproject = $biosample_dom->findvalue('/BioSample/Links/Link/@label');
    $self->bioproject($bioproject);
    my $bioproject_uid = $biosample_dom->findvalue('/BioSample/Links/Link');
    $self->bioproject_uid($bioproject_uid);
}

sub query_dom {
    my ($self, @fields) = @_;
    $self->fatal_message('No fields given to retrieve from NCBI XML DOM!') if not @fields;

    my $dom = $self->dom;
    my $attrs = { map { my $v = $dom->findvalue("//$_") || undef; $_ => $v } @fields };
    $attrs;
}

1;
