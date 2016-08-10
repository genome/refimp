package RefImp::Resources::LimsRestApi;

use strict;
use warnings 'FATAL';

use Data::Dumper 'Dumper';
use Params::Validate ':types';

use RefImp::Resources::SSO;

sub imp_lims_url {
    return 'https://imp-lims.gsc.wustl.edu/';
}

sub sso { return $_[0]->{sso}; }

sub new { 
    my $sso = RefImp::Resources::SSO->login(imp_lims_url());
    return bless { sso => $sso, }, __PACKAGE__;
}

sub query {
    my ($self, $object, $method) = Params::Validate::validate_pos(
        @_, {isa => __PACKAGE__,}, {isa => 'UR::Object',}, {type => SCALAR,},
    );

    my $url = $self->url_for_object_and_method($object, $method);
    my $data = $self->sso->request_json($url);

    if ( not $data->{data} or not ref $data->{data} eq 'ARRAY' ) {
        die sprintf('ERROR: Failed to get data for %s %s %s', $object->class, $object->id, $method);
    }

    my @values;
    for my $params ( @{$data->{data}} ) {
        push @values, $params and next if not ref $params;
        # Only supporting File::Path
        $params->{dir} = _decode( delete $params->{dir} );
        push @values, _decode($params);
    }

    return ( @values == 1 ) 
    ? return $values[0] 
    : ( wantarray ) ? @values : \@values;
}

sub _decode {
    my $params = shift;
    my $class = delete $params->{class};
    return bless $params, $class;
}

sub url_for_object_and_method {
    my ($self, $object, $method) = Params::Validate::validate_pos(
        @_, {isa => __PACKAGE__,}, {isa => 'UR::Object',}, {type => SCALAR,},
    );

    return sprintf(
        '%sapp?json={"object":{"class":"%s","id":"%s"},"method":"%s"}',
        $self->imp_lims_url,
        $self->resolve_gsc_class_for_object($object),
        $object->id,
        $method,
    );
}

sub resolve_gsc_class_for_object {
    my ($self, $object) = Params::Validate::validate_pos(
        @_, {isa => __PACKAGE__,}, {isa => 'UR::Object',},
    );

    # A little pre-emptive
    my %mapping = ();
    my $object_class = $object->class;
    return $mapping{$object_class} if exists $mapping{$object_class};

    $object_class =~ s/^RefImp/GSC/;
    return $object_class;
}

1;

