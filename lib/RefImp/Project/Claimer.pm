package RefImp::Project::Claimer;

use strict;
use warnings;

use RefImp;

use List::MoreUtils 'any';
use List::Util 'first';
use Params::Validate qw/ :types validate validate_pos /;

class RefImp::Project::Claimer { 
    has => {
        project => {
            is => 'RefImp::Project',
            id_by => 'project_id',
            doc => 'The project.',
        },
        user_funtion => {
            is => 'RefImp::User::Function',
            id_by => 'ei_id',
            doc => 'User function linked to this project.',
        },
        user => {
            is => 'RefImp::User',
            via => 'user_funtion',
            to => 'user',
            doc => 'User claimed this project.',
        },
        unix_login => {
            is => 'String',
            via => 'user',
            to => 'unix_login',
        },
    },
};

my %claim_types_and_funtions = (
    finisher => 'finish',
    prefinisher => 'prefinish',
    saver => 'finish',
);
sub valid_claim_types { keys %claim_types_and_funtions }
sub function_for_claim_type { $claim_types_and_funtions{$_[1]} }

sub class_for_claimer_type {
    my ($class, $type) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});
    $class->fatal_message('Invalid type! %s', $type) if not any { $type eq $_ } valid_claim_types();
    return join('::', 'RefImp', 'Project', ucfirst($type));
}

sub create_for_project_and_user {
    my $class = shift;
    my %params = validate(@_, {
            project => { isa => 'RefImp::Project', },
            user => { isa => 'RefImp::User', },
        });

    my $user = $params{user};
    my $claimer_function = $class->claimer_function_for_user($user);
    $class->fatal_message('No user functions for %s', $user->unix_login) if not $claimer_function;

    my $self = $class->create(
        ei_id => $claimer_function->id,
        project => $params{project},
    );
    $self->fatal_message('Failed tpo create project %s for %s!', $self->claimer_type, $user->unix_login) if not $self;

    return $self;
}

sub claimer_function_for_user {
    my ($self, $user) = validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::User'});

    my @functions = $user->functions;
    return if not @functions;
    my $type = $self->function_for_claim_type( $self->claimer_type );

    # active functions that match
    my $function = first { $_->name =~ /$type/i } grep { $_->is_active } @functions;
    return $function if $function;

    # inactive functions that match
    $function = first { $_->name =~ /$type/i } grep { !$_->is_active } @functions;
    return $function if $function;

    # ANY function...
    $functions[0];
}

1;

