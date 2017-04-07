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
    doc => 'update the status of projects',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    my $status = $self->value // '';
    my @rows = (
        [qw/ ID NAME STATUS OLD_STATUS /],
        [qw/ -- ---- ------ ---------- /],
    );
    for my $project ( $self->projects ) {
        my $old_status = $project->status;
        my $new_status = $project->status($status) if $status;
        my @row = map { $project->$_ } (qw/ id name status /);
        push @row, $old_status;
        push @rows, \@row;
    }

    print RefImp::Util::Tablizer->format(\@rows);
}

1;
