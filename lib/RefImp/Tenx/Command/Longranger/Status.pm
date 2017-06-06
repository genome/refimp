package RefImp::Tenx::Command::Longranger::Status;

use strict;
use warnings 'FATAL';

use Date::Format 'time2str';
use File::stat;
use IPC::Open3;
use List::MoreUtils;
use Path::Class;

class RefImp::Tenx::Command::Longranger::Status {
    is => 'Command::V2',
    has_input => {
        directory => {
            is => 'Text',
            #default_value => '/gscmnt/gc2745/graveslab/alignments/MMY_H_QD-WUPAT005-V0DHN2_with_pippen_size_selection-targeted-lsf',
        },
    },
    has_optional_input => {
        show_log_tail => {
            is => 'Boolean',
            doc => 'Print the tail of the log file.',
        },
    },
    has_calculated_constant_optional => {
        _directory => { calculate_from => [qw/ directory /], calculate => q| Path::Class::dir($directory) |, },
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

The tail of the log file is inspected looking for 2 known strings that indicate
if the run has completed successfully. If "Pipestance completed successfully" is
found, then the run is SUCCEEDED. If "Pipestance failed" is found, then the run
tatus is FAILED. If niether of these is found, the log status will be RUNNING.
The log access time will be reported, but the log may go a long time between
writes. If the log status is not RUNNING, they journal status will ot be reported.

Journal Directory

The journal directrory  is often accessed throughoutthe run and is a good
indicator of the longranger run status. Journal acceess time doesn't typically
lag more than a couple of minutes. The time since last access threshold is 10
miunutes. If the journal has been accessed within 10 minutes, the status is PASS,
other wise it is FAIL.

HELP
}

sub execute {
    my $self = shift;

    $self->status_message('Longranger Run Status...');
    $self->status_message('Directory:        %s', $self->directory);
    $self->status_message('Current time:     %s', time2str($self->datetime_format, $self->now));
    my $log_status = $self->_log;
    $self->_journal if $log_status eq 'running';

    1;
}

sub _journal {
    my $self = shift;

    my $journal_path = $self->_directory->subdir('journal');
    my $journal_st = stat($journal_path) or die "$!";
    $self->status_message('Journal accessed: %s', time2str($self->datetime_format, $journal_st->mtime));
    my $journal_access_min = (($self->now - $journal_st->mtime) / 60);
    $self->status_message('Minutes since:    %.1f', $journal_access_min);
    my $journal_status = ( $journal_access_min < 10 ? 'pass' : 'fail' );
    $self->status_message('Journal status    %s', uc $journal_status);
    $journal_status;
}

sub _log {
    my $self = shift;

    my $log_file = $self->_directory->file('_log');
    my $log_st = stat($log_file) or die "$!",

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
        my $error_file = dir($self->directory)->parent->file($log_tail[-2]);
        print "$error_file\n";
        if ( -e "$error_file" ) {
            my $error_content = $error_file->slurp($error_file);
            print "$error_content\n";
        }
        #H_QD-WAPAT022-V0DHO7_targetde/PHASER_SVCALLER_EXOME_CS/PHASER_SVCALLER_EXOME/_SNPINDEL_PHASER/_SNPINDEL_CALLER/POPULATE_INFO_FIELDS/fork0/chnk0/_errors
    }

    $self->status_message('Log accessed:     %s', time2str($self->datetime_format, $log_st->mtime));
    $self->status_message(join('', @log_tail)) if $self->show_log_tail;
    $self->status_message('Log status:       %s', uc $status);
    $status;
}

1;
