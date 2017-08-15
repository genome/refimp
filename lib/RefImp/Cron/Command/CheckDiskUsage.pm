package RefImp::Cron::Command::CheckDiskUsage;

use strict;
use warnings 'FATAL';

use Filesys::Df 'df';
use RefImp::Util::Tablizer;

class RefImp::Cron::Command::CheckDiskUsage {
    is => 'Command::V2',
    has_input => {
        groups => {
            is => 'RefImp::Disk::Group',
            is_many => 1,
            doc => 'Disk groups to gather volumes',
        },
    },
    has_optional_input => {
        threshold => {
            is => 'Number',
            value => 95,
            doc => 'Threshold percentage to decide if a volume passes or not',
        },
    },
    doc => 'check percent used for disks by group',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message("Disk Usage Check...");

    my @groups = $self->groups;
    $self->status_message('Disk groups: %s', join(' ', map { $_->disk_group_name } @groups));

    my $threshold = $self->threshold;
    $self->status_message('Threshold: %s', $threshold);

    my @data = [qw/ PATH GROUP SIZE USED STATUS /];
    for my $group ( $self->groups ) {
        VOLUME: for my $volume ( $group->volumes ) {
            my $mount_path = $volume->mount_path;
            my @row = ( $mount_path, $group->disk_group_name, );
            if ( !-d $mount_path ) {
                $self->warning_message('Volume %s is not mounted!', $mount_path);
                push @row, 'NaN', 'NaN', 'ERROR';
            }
            else {
                my $df = df($mount_path);
                push @row, sprintf('%0.1fT', ($df->{blocks} / (1024 * 1024 * 1024))), sprintf('%d%%', $df->{per}), ( $df->{per} <  $threshold ? 'PASS' : 'FAIL' );
            }
            push @data, \@row;
        }
    }
    
    print RefImp::Util::Tablizer->format(\@data);
}

1;
