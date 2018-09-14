package Tenx::Alignment::Command::Status;

use strict;
use warnings 'FATAL';

use Date::Format 'time2str';
use File::stat;
use IPC::Open3;
use List::MoreUtils;
use Path::Class;

class Tenx::Alignment::Command::Status {
    is => 'Command::V2',
    has_input => {
        alignment => {
            is => 'Tenx::Alignment',
            shell_args_position => 1,
            doc => 'Longranger alignment to check status.',
        },
    },
    has_optional_input => {
        show_log_tail => {
            is => 'Boolean',
            doc => 'Print the tail of the log file.',
        },
    },
    has_calculated_constant_optional => {
        _directory => { calculate_from => [qw/ alignment /], calculate => q| Path::Class::dir($alignment->directory) |, },
    },
    has_constant => {
        datetime_format => { value => '%Y-%m-%d %H:%M:%S', },
        now => { value => time(), },
    },
    doc => 'determine the status of a longranger run',
};

sub help_detail {
    return <<HELP;

Checks log and journal and tries to determine the longranger run status.

Log File

The tail of the log file is inspected looking for 2 known strings that indicate if the run has completed successfully. If "Pipestance completed successfully" is found, then the run is SUCCEEDED. If "Pipestance failed" is found, then the run tatus is FAILED. If niether of these is found, then the journal status will be used to refine the status.

Journal Directory

The journal directrory is often accessed throughout the run and is a good indicator of the longranger run status. Journal acceess time doesn't typically lag more than a couple of minutes. The time since last access threshold is 10 miunutes. If the journal has been accessed within 10 minutes, the status will be RUNNING. If the log does not have success/failure in it, and the journal hasd not been accessed for 10+ minutes, the status will be DIED.

HELP
}

sub execute {
    my $self = shift;

    $self->status_message('Longranger Run Status...');
    $self->status_message('Directory:        %s', $self->_directory);
    $self->status_message('Current time:     %s', time2str($self->datetime_format, $self->now));
    my $status = $self->_resolve_status_from_log;
    return 1 if $status ne 'running';
    $self->_refine_status_from_journal;

    1;
}

sub _resolve_status_from_log {
    my $self = shift;
    $self->status_message('Resolving status from log...');

    my $log_file = $self->_directory->file('_log');
    my $log_st = stat("$log_file") or die "$!",

    my($wtr, $rdr, $err);
    my $pid = open3($wtr, $rdr, $err, 'tail', $log_file->stringify);
    waitpid( $pid, 0);
    my @log_tail = <$rdr>;
    my $status = 'running';
    if ( List::MoreUtils::any { $_ =~ /Pipestance completed successfully/ } @log_tail ) {
        $status = 'succeeded';
    }
    elsif ( List::MoreUtils::any { $_ =~ /Pipestance failed/ } @log_tail ) {
        $status = 'failed';
        my $error_file = $self->_directory->parent->file($log_tail[-2]);
        chomp $error_file;
        if ( -e "$error_file" ) {
            my $error_content = $error_file->slurp($error_file);
            print "$error_content\n";
        }
    }

    $self->status_message('Log accessed:     %s', time2str($self->datetime_format, $log_st->mtime));
    $self->status_message(join('', @log_tail)) if $self->show_log_tail;
    $self->status_message('Status:           %s', uc $status);
    $status;
}

sub _refine_status_from_journal {
    my $self = shift;
    $self->status_message('Refining status from journal...');

    my $journal_path = $self->_directory->subdir('journal');
    my $journal_st = stat($journal_path) or die "$!";
    $self->status_message('Journal accessed: %s', time2str($self->datetime_format, $journal_st->mtime));
    my $journal_access_min = (($self->now - $journal_st->mtime) / 60);
    $self->status_message('Minutes since:    %.1f', $journal_access_min);
    my $journal_status = ( $journal_access_min < 10 ? 'pass' : 'fail' );
    $self->status_message('Journal status:   %s', uc $journal_status);

    my $status = 'running';
    $status = 'died' if $journal_status eq 'fail';
    $self->status_message('Status:           %s',  uc $status);
    $status;
}

1;
