package RefImp::Project::Command::Status;

use strict;
use warnings;

use Util::Tablizer;

class RefImp::Project::Command::Status { 
    is => 'RefImp::Project::Command::BaseWithMany',
    doc => 'show status and accessions',
};

sub help_detail { $_[0]->__meta__->doc }
    
sub _execute_with_project { 1 }

sub _after_execute {
    my $self = shift;

    my @rows = (
        [qw/ NAME STATUS ACCESSIONS /],
        [qw/ ---- ------ ---------- /],
    );

    for my $project ( $self->projects ) {
        my @row = map { $project->$_ // 'NA' } (qw/ name status /);
        my @accessions =  map { $_->accession_id } sort { $a cmp $b } $project->submissions;
        push @row, ( @accessions ? join(' ', @accessions) : 'NA');
        push @rows, \@row;
    }

    print Util::Tablizer->format(\@rows);
}

1;
