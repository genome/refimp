package RefImp::Cron::Command::CheckDiskUsage;

use strict;
use warnings 'FATAL';

use Filesys::Df 'df';
use IO::File;
use RefImp::Util::Tablizer;

class RefImp::Cron::Command::CheckDiskUsage {
    is => 'Command::V2',
    has_input => {
        groups => {
            is => 'RefImp::Disk::Group',
            is_many => 1,
            require_user_verify => 0,
            doc => 'Disk groups to gather volumes',
        },
    },
    has_optional_input => {
        html => {
            is => 'Boolean',
            doc => 'Output as html table.',
        },
        threshold => {
            is => 'Number',
            value => 95,
            doc => 'Threshold percentage to decide if a volume passes or not',
        },
    },
    has_optional_output => {
        output_file => {
            is => 'Text',
            doc => 'Send output to this file instead of to STDOUT.',
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
    
    $self->_output(\@data);
}

sub _output {
    my ($self, $data) = @_;

    my $output;
    if ( $self->html ) {
        $output = RefImp::Util::Tablizer->as_html($data);
    }
    else {
        $output = RefImp::Util::Tablizer->format($data);
    }

    if ( $self->output_file ) {
        my $fh = IO::File->new($self->output_file, 'w');
        $fh->print($output);
        $fh->close;
    }
    else {
        print STDOUT $output;
    }
}

1;
