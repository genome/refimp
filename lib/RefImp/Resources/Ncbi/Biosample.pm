package RefImp::Resources::Ncbi::Biosample;

use strict;
use warnings 'FATAL';

use LWP::UserAgent;
use XML::LibXML;

class RefImp::Resources::Ncbi::Biosample {
    has => {
        biosample => { is => 'Text', },
        bioproject => { is => 'Text', },
    },
    has_calculated => {
        bioproject_uid => {
            is => 'Text',
            calculate_from =>[qw/ bioproject /],
            calculate => q| $bioproject =~ s/\D//g; $bioproject =~ s/^0+//; $bioproject; |,
        },
        biosample_uid => {
            is => 'Text',
            calculate_from =>[qw/ biosample /],
            calculate => q| $biosample =~ s/\D//g; $biosample =~ s/^0+//; $biosample; |,
        },
    },
    has_optional_transient => {
        elink_xml => { is => 'Text', },
        ua => { },
    },
    doc => 'NCBI E-Utils Biosample Helper',
};

sub esummary_url { # currently unused, keeping for notes
    sprintf(
        'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?dbfrom=bioproject&db=biosample&id=%s',
        $_[0]->biosample_uid,
    );
}

sub elink_url {
    sprintf(
        'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=bioproject&db=biosample&id=%s',
        $_[0]->bioproject_uid,
    );
}

sub create {
    my $class = shift;
    
    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->fatal_message('No bioproject given!') if not $self->bioproject;
    $self->fatal_message('No biosample given!') if not $self->biosample;

    $self->__init__;
}

sub __init__ {
    my $self = shift;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    $self->ua($ua);

    $self->load_elink_xml;
    $self;
}

sub fetch_xml_dom {
    my ($self, $type) = @_;

    $self->fatal_message('No URL type given to fetch XML DOM!') if not $type;

    my $url_method = join('_', $type, 'url');
    my $url = $self->$url_method;
    my $response = $self->ua->get($url);
    if ( not $response->is_success ) {
        $self->fatal_message('Failed to GET %s', $url);
    }

    my $content = $response->decoded_content;
    my $dom = XML::LibXML->load_xml(string => $content);
    my $error = $dom->findvalue('//error');
    $self->fatal_message("NCBI %s XML DOM error: %s", $type, $error) if $error;

    my $content_method = join('_', $type, 'xml');
    $self->$content_method($content);

    $dom
}

sub load_elink_xml {
    my $self = shift;

    my $dom = $self->fetch_xml_dom('elink');
    my $biosample_uid = $self->biosample_uid;
    my @links = $dom->findnodes('/eLinkResult/LinkSet/LinkSetDb/Link/Id');
    $self->fatal_message("No bioproject/biosample links found in elink xml!\n%s", $self->elink_xml) if not @links;
    my ($bioproject_link) = grep { $_->textContent eq $biosample_uid } @links;
    $self->fatal_message('Could not find bioproject/biosample %s/%s link!', $self->bioproject, $self->biosample) if not $bioproject_link;
};

1;
