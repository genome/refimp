package RefImp::Tenx::Command::Reference::Mkref;

use strict;
use warnings;

use Cwd qw( chdir cwd );
use File::Slurp;
use File::Temp 'tempfile';
use Path::Class;
use IPC::Open3;

use RefImp::Tenx::Reference;
my %inputs = map {
    $_->property_name => {
        is => $_->data_type,
        doc => $_->doc,
    }
} map {
    RefImp::Tenx::Reference->__meta__->property_meta_for_name($_) 
} (qw/ name taxon /);

class RefImp::Tenx::Command::Reference::Mkref { 
    is => 'Command::V2',
    has_input => {
        %inputs,
        fasta_file => {
            is => 'Text',
            doc => 'Fasta to run mkref on.',
        },
    },
    has_optional_constant_calculated => {
        output_directory => {
            calculate_from => [qw/ _fasta_file /],
            calculate => q| $_fasta_file->parent |,
        },
        reference_directory => {
            calculate_from => [qw/ _fasta_file output_directory /],
            calculate => q|
                my $fasta_file_basename = $_fasta_file->basename;
                $fasta_file_basename =~ s/\.\w+$//;
                $output_directory->subdir('refdata-'.$fasta_file_basename);
            |,
        },
        _fasta_file => {
            calculate_from => [qw/ fasta_file /],
            calculate => q| Path::Class::file($fasta_file) |,
        },
    },
    has_optional_transient => {
        bsub_out_file => { is => 'Class::Path::File', },
    },
    doc => 'run longranger mkref and make reference db entry',
};

sub help_detail {
<<HELP;
Run mkref on a fasta to make a longranger compatible reference.

Output refence files are stored in the directory thatthis command is run in!

HELP
}

sub execute {
    my $self = shift; 
    $self->status_message('Reference Mkref...');

    $self->_validate_pre_tenx_command;
    $self->_run_tenx_command;
    $self->_validate_post_tenx_command;
    $self->_create_db_entity;

    1;
}

sub _validate_pre_tenx_command {
    my $self = shift;

    my $reference = RefImp::Tenx::Reference->get(name => $self->name);
    $self->fatal_message('Reference for %s already exists: %s', $self->name, $reference->__display_name__) if $reference;
    $self->fatal_message('Fasta file %s does not exist!', $self->fasta_file) if not -s $self->_fasta_file->stringify;
}

sub _bsub_command {
    my $self = shift;
    my $mem = 8000;
    my $queue = 'lims-pd-long';
    (
        'bsub', '-K',
        '-R', "select[mem>$mem] rusage[mem=$mem]",
        '-M', ( $mem * 1200  ),
        '-oo', $self->bsub_out_file->stringify,
        '-q', $queue,
        '-a', 'docker(registry.gsc.wustl.edu/ebelter/longranger:2.1.3)',
    );
}

sub _tenx_command {
    my $self = shift;
    (qw/ longranger mkref /, $self->_fasta_file->stringify );
}

sub _run_tenx_command {
    my $self = shift;

    my $old_cwd = cwd();
    $self->status_message('Entering %s', $self->output_directory);
    $self->status_message('CWD %s', $ENV{PWD});
    chdir $self->output_directory->stringify;
    $self->status_message('CWD %s', $ENV{PWD});

    my ($out_fh, $out_file_name) = File::Temp::tempfile('mkref-out-XXXXXXX', UNLINK => 1);
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

    $self->status_message('Mkref exit code: %s', $child_exit_status);
    $self->fatal_message('Mkref failed!') if $child_exit_status != 0;
}

sub _validate_post_tenx_command {
    my $self = shift;
    # Check for in out file: Reference successfully created
    #
    $self->status_message('Reference directory: %s', $self->output_directory->stringify);
    $self->fatal_message('Output mkref directory does not exist!') if not -d $self->output_directory->stringify;
}

sub _create_db_entity {
    my $self = shift;
    RefImp::Tenx::Command::Reference::Create->execute(
        name => $self->name,
        directory => $self->reference_directory->stringify,
        taxon => $self->taxon,
    );
}

1;
