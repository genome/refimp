package RefImp::Resources::SSO;

use strict;
use warnings 'FATAL';

use Genome::Config;
use JSON;
use LWP::UserAgent;
use Params::Validate ':types';
use Try::Tiny;
use WWW::Mechanize;

sub user_agent { return $_[0]->{user_agent}; }

sub login { # new
    my ($class, $url) = Params::Validate::validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    my $mech = WWW::Mechanize->new(
        after =>  1,
        timeout => 10,
        agent =>  'WWW-Mechanize',
    );
    $mech->get($url);

    my $host = $mech->uri->host;
    if ($host ne 'sso.gsc.wustl.edu') {
        return; # logged in? return object?
    }

    $mech->submit_form (
        form_number =>  1,
        fields =>  {
            j_username => Genome::Config::get('rt_login'),
            j_password => Genome::Config::get('rt_auth'),
        },
    );
    $mech->submit();

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    $ua->cookie_jar($mech->{cookie_jar});

    return bless { 
        url => $url,
        user_agent => $ua,
    }, $class;
}

sub request_json {
    my ($self, $url) = Params::Validate::validate_pos(@_, {isa => __PACKAGE__,}, {type => SCALAR,},);

    my $response = $self->user_agent->get($url);
    if ( not $response->is_success ) {
        printf(STDERR "ERROR: %s\n", $response->status_line);
        die sprintf("ERROR: Failed to get a response for URL: %s", $url);
    }

    #my $json = JSON->new->utf8;
    #$json->convert_blessed(1);
    my $json = JSON->new->allow_nonref;
    my $data;
    try { 
        $data = $json->decode( $response->decoded_content );
    }
    catch { 
        my $err = $_;
        printf(STDERR "ERROR: %s\n", $err);
        die sprintf("ERROR: Failed to decode content to json! %s", $response->decoded_content);
    };

    return $data;
}

1;

