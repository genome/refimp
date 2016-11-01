package RefImp::Project::Digest;

use strict;
use warnings;

use Params::Validate qw/ :types validate_pos /;

sub new {
    my ($class, %params) = @_;

    my $self = bless(\%params, $class);

    return $self;
}

sub project_basename {
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

1;

