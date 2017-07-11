package RefImp::Tenx::Command::LongrangerBase;

use strict;
use warnings;

use Cwd qw( chdir cwd );
use File::Slurp;
use File::Temp 'tempfile';
use Path::Class;
use IPC::Open3;

class RefImp::Tenx::Command::LongrangerBase { 
    is => 'Command::V2',
    is_abstract => 1,
    has_optional => {
        bsub_queue => { is => 'Text', default_value => 'long', doc => 'Bsub queue to execute longranger.', },
        bsub_mem => { is => 'Text', default_value => '8000', doc => 'Bsub mem in MB.', },
        bsub_cores => { is => 'Text', default_value => '1', doc => 'Bsub number of cores.', },
    },
    has_optional_transient => {
        bsub_out_file => { is => 'Class::Path::File', },
    },
    doc => 'longranger base command',
};

sub execute {
    my $self = shift; 

    $self->_validate_pre_tenx_command;
    $self->_run_tenx_command;
    $self->_validate_post_tenx_command;
    $self->_create_db_entities;

    1;
}

sub _validate_pre_tenx_command { die 'Overload _validate_pre_tenx_command' }
sub _tenx_command { die 'Overload _tenx_command' }
sub _validate_post_tenx_command { die 'Overload _validate_post_tenx_command' }
sub _create_db_entities { die 'Overload _create_db_entities' }

sub _bsub_command {
    my $self = shift;
    my $mem = $self->bsub_mem;
    (
        'bsub', '-K',
        '-R', "select[mem>$mem] rusage[mem=$mem]",
        '-M', sprintf('%.0f', $mem * 1200),
        '-oo', $self->bsub_out_file->stringify,
        '-q', $self->bsub_queue,
        '-n', $self->bsub_cores,
        '-a', 'docker(registry.gsc.wustl.edu/ebelter/longranger:2.1.3)',
    );
}

sub _run_tenx_command {
    my $self = shift;

    my $old_cwd = cwd();
    $self->status_message('Entering %s', $self->output_directory);
    $self->status_message('CWD %s', $ENV{PWD});
    chdir $self->output_directory->stringify;
    $self->status_message('CWD %s', $ENV{PWD});

    my ($out_fh, $out_file_name) = File::Temp::tempfile('longranger-out-XXXXXXX', UNLINK => 1);
    my $out_file = $self->bsub_out_file( Path::Class::file($out_file_name)->absolute );
    $self->status_message('Out file: %s', $out_file);

    my @cmd = $self->_bsub_command;
    push @cmd, $self->_tenx_command;
    $self->status_message('Run: %s', join(' ', @cmd));

    my ($wtr, $rdr, $err);
    my $pid = IPC::Open3::open3($wtr, $rdr, $err, @cmd);
    waitpid($pid, 0);
    my $child_exit_status = $? >> 8;

    my $out_file_contents = File::Slurp::slurp($out_file->stringify);
    unlink $out_file->stringify;
    $self->status_message($out_file_contents);

    $self->status_message('Returning to %s', $old_cwd);
    chdir $old_cwd;
    $self->status_message('CWD %s', $ENV{PWD});

    $self->status_message('Longranger exit code: %s', $child_exit_status);
    $self->fatal_message('Longranger failed!') if $child_exit_status != 0;
}

1;
