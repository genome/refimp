package RefImp::Project::Command::Update::Status;

use strict;
use warnings;

use RefImp::Util::Tablizer;

class RefImp::Project::Command::Update::Status { 
    is => 'RefImp::Project::Command::BaseWithMany',
    has_optional_input => {
        value => {
            is => 'String',
            doc => 'Status to set on the given projects.',
        },
    },
    has_optional => {
        old_values => { is => 'ARRAY', default_value => [], },
    },
    doc => 'update the status of projects',
};

sub help_detail { $_[0]->__meta__->doc }

sub _execute_with_project {
    my ($self, $project) = @_;
    push @{$self->old_values}, $project->status;
    $project->status($self->value) if $self->value;
}

sub _after_execute {
    my $self = shift;

    my @rows = (
        [qw/ ID NAME STATUS OLD_STATUS /],
        [qw/ -- ---- ------ ---------- /],
    );

    my $old_values = $self->old_values;
    my $i = 0;
    for my $project ( $self->projects ) {
        push @rows, [ map({ $project->$_ } (qw/ id name status /)), $old_values->[$i] ];
        $i++;
    }

    print RefImp::Util::Tablizer->format(\@rows);
}

1;
