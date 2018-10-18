package Tenx::Util::Run::Log;

use strict;
use warnings 'FATAL';

use DateTime;
use List::MoreUtils 'firstval';
use Path::Class;
use Tenx::Util::Reader::Factory;

class Tenx::Util::Run::Log {
    has => {
        log_file => {
            is => 'Path::Class::File',
            doc => 'Log file to analyze.',
        },
        time_zone => {
            is => 'String',
            default_value => 'UTC', # America/Chicago
            doc => 'Time zone where the log file was generated.'
        },
    },
    has_optional_transient => {
        infos => { is => 'Array', },
        run_status => { is => 'Text', },
        stages => { is => 'Array', },
        reader => { is => 'Tenx::Util::Reader', },
    },
};

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;
    
    $self->_load_log;
    $self->_parse_log;
    $self->_process_log_info;
    $self->_resolve_status;

    $self;
}

sub _load_log {
    $_[0]->reader( Tenx::Util::Reader::Factory->build_reader($_[0]->log_file) );
}

sub _parse_log {
    my ($self) = @_;

    my @infos;
    while ( my $line = $self->reader->getline ) {
        my $info = _parse_line($line);
        next if not $info;
        push @infos, $info;
    }

    $self->infos(\@infos);
}

sub _parse_line {
    my ($line) = @_;

    return if $line !~ /^\d\d\d\d\-/;

    my (%info, $rest);
    chomp $line;
    ($info{date}, $info{time}, $rest) = split(/\s+/, $line, 3);
    ($info{program}, $rest) = split(/\s+/, $rest, 2);
    $info{program} =~ s/[\[\]]//g;

    return if $info{program} ne 'runtime';

    ($info{status}, $rest) = split(/\s+/, $rest, 2);
    return if not $info{status} =~ s/[\(\)]//g;

    # ID.H_VL-MI-00412-FR04507719.ASSEMBLER_CS._ASSEMBLER._ASSEMBLER_PREP._FASTQ_PREP_NEW.BUCKET_FASTQS.fork0 chunks running (0/6 completed)
    ($info{stage_str}, $rest) = split(/\s+/, $rest, 1);
    my @stage = split(/\./, $info{stage_str});
    shift @stage; # 'ID'
    shift @stage; # RUN ID
    shift @stage; # MAIN STAGE
    for my $step ( @stage ) {
        last if $step =~ /^fork/;
        $step =~ s/^_//;
        push @{$info{stage}}, $step;
    }

    \%info;
}

sub _process_log_info {
    my ($self) = @_;

    my @stages;
    my $order = 0;
    for my $info ( @{$self->infos} ) {
        my $name = join(' ', @{$info->{stage}});
        my $stage = firstval { $_->{name} eq $name } @stages;
        if ( not $stage ) {
            $stage = {
                name => $name,
                order => ++$order,
                status => 'run',
            };
            push @stages, $stage;
        }
        if ( $info->{status} eq 'ready' ) {
            $stage->{start} = $self->_parse_date_time($info->{date}, $info->{time});
        }
        elsif ( $info->{status} eq 'chunks_complete' ) {
            $stage->{stop} = $self->_parse_date_time($info->{date}, $info->{time});
            $stage->{status} = 'done';
        }
        elsif ( $info->{status} eq 'failed' ) {
            $stage->{status} = 'fail';
        }
    }
    
    $self->stages(\@stages);
}

sub _parse_date_time {
    my ($self, $date, $time) = @_;

    # 2018-02-27 && 08:02:43
    my ($year, $month, $day) = split(/\-/, $date);
    my ($hour, $min, $sec) = split(/:/, $time);

    DateTime->new(
        year       => $year,
        month      => $month,
        day        => $day,
        hour       => $hour,
        minute     => $min,
        second     => $sec,
        time_zone  => $self->time_zone,
    );
}

sub _resolve_status {
    my ($self) = @_;

    my @lines = $self->reader->reset->getlines;
    my $last = $#lines;
    my $start = $last - 10;
    my $status;
    foreach my $line ( @lines[$start .. $last] ) {
        if ( $line =~ /Pipestance completed successfully/ ) {
            return $self->run_status('success');
        }
        elsif ( $line =~ /error/i ) {
            return $self->run_status('failed');
        }
    }

    $self->run_status('running');
}

1;
