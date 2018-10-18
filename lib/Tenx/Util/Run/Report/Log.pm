package Tenx::Util::Run::Report::Log;

use strict;
use warnings 'FATAL';

use DateTime;

sub generate_stage_status {
    my ($infos, $run) = @_;

    my $log = $run->log;
    my $report = sprintf("STATUS:   %s\n", $log->run_status);
    #my $last = $#{$infos};
    #printf("LAST LOG: %s %s\n", $infos->[$last]->{date}, $infos->[$last]->{time});

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
