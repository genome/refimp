package Refimp::Project::Digest;

use strict;
use warnings;

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/ bands date enzyme project_basename project_header project_name /);

use Params::Validate qw/ :types validate_pos /;
use Refimp::Project::Digest::Enzymes;

sub new {
    my ($class, $project_name) = @_;

    my $self = bless({project_name => $project_name}, $class);
    die "ERROR No project name given to create digest!" if not $self->project_name;

    $self->project_basename( $self->resolve_project_basename($self->{project_name}) );

    return $self;
}

sub resolve_project_basename {
    my ($self, $name) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    if ( $name =~ /^C_AD-/) {
        return substr($name, 5);
    }
    elsif( $name =~ /^(CB|JB|JE|JH)/ && length( $name ) > 4 ) {
        return substr($name, 2);
    }
    elsif ( $name =~ /^VMRC/) {
        return substr($name, 3);
    }

    substr($name, 4);
}

sub add_digest_info {
    my ($self, %info) = @_;

    die 'ERROR Cannot add digest info twice!' if $self->project_header;
    die 'ERROR No project header in info!' if not exists $info{project_header};

    my $project_basename = $self->project_basename;
    return if not $info{project_header} =~ /^$project_basename/;

    for my $attr (qw/ bands date project_header /) {
        die "ERROR No $attr name given to create digest!" if not exists $info{$attr};
        $self->$attr( delete $info{$attr} );
    }

    my $enzyme_code = $self->project_header;
    $enzyme_code =~ s/^$project_basename//;
    $self->enzyme( Refimp::Project::Digest::Enzymes->enzyme_for_code($enzyme_code) );

    return 1;
}

1;

