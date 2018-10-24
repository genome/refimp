package Tenx::Util::Command::Run::Duration;

use strict;
use warnings 'FATAL';

use DateTime;
use Path::Class;
use Tenx::Util::Run;

class Tenx::Util::Command::Run::Duration {
    is => 'Command::V2',
    has => {
        directory => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'TenX Run directory for longranger, supernova, or cellranger',
        },
    },
};

sub execute {
    my $self = shift;
    print $self->generate_stage_status( Tenx::Util::Run->new( dir( $self->directory ) ) );
}

sub generate_stage_status {
    my ($self, $run) = @_;

    my $log = $run->log;
    my $report = sprintf("STATUS:   %s\n", $log->run_status);
    my $stages = $log->stages;
    for my $stage ( @$stages ) {
        my $duration = 1;
        if ( not $stage->{stop} ) {
            $stage->{stop} = DateTime->now(time_zone => $log->time_zone);
        }
        $duration = _format_duration( $stage->{start}->delta_ms($stage->{stop}) );
        $report .= sprintf("%s %-4s %s\n", $duration, $stage->{status}, $stage->{name});
    }

    my $last = $#{$stages};
    $report .= sprintf("%s %-4s TOTAL\n", _format_duration($stages->[0]->{start}->delta_ms($stages->[$last]->{stop})), $stages->[$last]->{status});
}

sub _format_duration {
    my ($duration) = @_;

    my $h = $duration->in_units('hours');
    my $m = $duration->in_units('minutes') - ( $h * 60 );
    my $s = $duration->in_units('seconds');

    my $d = int( $h / 24 );
    $h = $h % 24;

    sprintf("%dd %02dh %02dm %02ds", $d, $h, $m, $s);
}

1;
