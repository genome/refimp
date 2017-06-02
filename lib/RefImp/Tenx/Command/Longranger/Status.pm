#!/usr/bin/env perl5.12.1

use strict;
use warnings 'FATAL';

package RefImp::Tenx::Longranger::Status;

use UR;

use Date::Format 'time2str';
use File::stat;
use IPC::Open3;
use Path::Class;

class RefImp::Tenx::Longranger::Status {
    is => 'Command::V2',
    has_input => {
        directory => {
            is => 'Text',
            default_value => '/gscmnt/gc2745/graveslab/alignments/MMY_H_QD-WUPAT005-V0DHN2_with_pippen_size_selection-targeted-lsf',
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
        datetime_format => { default_value => '%Y-%m-%d %H:%M:%S', },
        now => { default_value => time(), },
    },
    has_optional_transient => {
        journal_status => { is => 'Text', },
    },
    doc => '',
};

sub execute {
    my $self = shift;

    $self->status_message('Longranger Run Status...');
    $self->status_message('Current time:     %s', time2str($self->datetime_format, $self->now));
    $self->_journal;
    $self->_log;

    1;
}

sub _journal {
    my $self = shift;

    my $journal_path = $self->_directory->subdir('journal');
    my $journal_st = stat($journal_path) or die "$!";
    $self->status_message('Journal accessed: %s', time2str($self->datetime_format, $journal_st->mtime));
    my $journal_access_min = (($self->now - $journal_st->mtime) / 60);
    $self->status_message('Minutes since:    %.1f', $journal_access_min);
    my $journal_status = ( $journal_access_min < 10 ? 'PASS' : 'FAIL' );
    $self->status_message('Journal status    %s', $journal_status);
    $self->journal_status($journal_status);
}

sub _log {
    my $self = shift;

    my $log_file = $self->_directory->file('_log');
    my $log_st = stat($log_file) or die "$!",

    my($wtr, $rdr, $err);
    #use Symbol 'gensym'; $err = gensym;
    my $pid = open3($wtr, $rdr, $err, 'tail', $log_file->stringify);
    waitpid( $pid, 0);
    while (<$rdr>) { print }

    $self->status_message('Log accessed:     %s', time2str($self->datetime_format, $log_st->mtime));
}

package main;

RefImp::Tenx::Longranger::Status->execute_with_shell_params_and_exit;
1;
