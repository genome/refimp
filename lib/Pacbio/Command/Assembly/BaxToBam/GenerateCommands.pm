package Pacbio::Command::Assembly::BaxToBam::GenerateCommands;

use strict;
use warnings 'FATAL';

use IO::File;
use List::Util;
use Pacbio::Run;
use Pacbio::Run::AnalysisFactoryForRsii;
use Path::Class;

class Pacbio::Command::Assembly::BaxToBam::GenerateCommands {
    is => 'Command::V2',
    has_input => {
        bam_to_bax_command => {
            is => 'Text',
            doc => 'Command to fill in with BAX files and logging files. BAX files will be appended to the command. Use %LOG for the log file base name for each cell.  Example: bsub -o /my-logging-dir/%LOG bam2bax',
        },
        bax_sources => {
            is => 'Text',
            is_many => 1,
            doc => 'Pacbio run directories OR FOF of bax files.',
        },
    },
    has_optional_input => {
        bam_output_directory => {
            is => 'Text',
            doc => 'Give the bam output directory to check if the bam already exists. If so, the bax2bam command for that cell will not be printed.',
        },
        library_name => {
            is => 'Text',
            default_value => '.',
            doc => "The library name to query to match a run's anaylses bax files. If not given, all analyses from the runs will be used.",
        },
    },
    has_optional_output => {
        commands_file => {
            is => 'Text',
            default_value => '-',
            doc => 'Output file to print commands. Defaults to STDOUT.',
        },
    },
    has_optional_transient => {
        _analyses => { is => 'ARRAY', },
        _commands_fh => { },
        _bam_output_directory => { is => 'Text', },
    },
    doc => 'insert missing primary contigs from haplotigs',
};

sub __init__ {
    my ($self) = @_;

    my @bax_sources = $self->bax_sources;
    if ( @bax_sources == 1 and -f $bax_sources[0] ) {
        $self->_resolve_analyses_from_bax_fof($bax_sources[0]);
    }
    elsif ( List::Util::all { -d $_ } @bax_sources ) {
        $self->_resolve_analyses_from_runs(@bax_sources);
    }
    else {
        $self->fatal_message('Can not handle mix of run directories and bax FOFs! %s', join("\n", @bax_sources));
    }
    $self->fatal_message("No analyses found in bax sources!\n%s", join("\n", @bax_sources)) if not @{$self->_analyses};

    my $commands_file = $self->commands_file;
    if ( $commands_file and $commands_file ne '-' and -s $commands_file ) {
        $self->fatal_message("Output commands file exists: $commands_file. Please change detination, or remove it.");
    }

    $self->_commands_fh(
        ( $commands_file eq '-' )
        ? 'STDOUT'
        : IO::File->new($commands_file, 'w')
    );
    $self->fatal_message('Failed to open commands file! %s', $commands_file) if not $self->_commands_fh;

    my $bam_output_directory = $self->bam_output_directory;
    if ( $bam_output_directory ) {
        $self->fatal_message('Given bam output directory, but it does not exist!') if not -d $bam_output_directory;
        $self->_bam_output_directory( Path::Class::dir($bam_output_directory) );
    }

}

sub _resolve_analyses_from_bax_fof {
    my ($self, $bax_fof) = @_;

    my $fh = IO::File->new($bax_fof, 'r');
    $self->fatal_message('Failed to open bax FOF!') if not $fh;
    my @analysis_directories = List::MoreUtils::uniq( map { chomp; file($_)->parent->parent } $fh->getlines );
    $fh->close;

    my @analyses = map { Pacbio::Run::AnalysisFactoryForRsii->build_from_analysis_directory($_) } @analysis_directories;
    $self->_analyses(\@analyses);
}

sub _resolve_analyses_from_runs {
    my ($self, @runs) = @_;

    my $library_name = $self->library_name;
    my $regex = qr/$library_name/;
    my @analyses;
    for my $directory ( $self->bax_sources ) {
        my $run = Pacbio::Run->new(
            directory => Path::Class::dir($directory),
            machine_type => 'rsii',
        );
        my $run_analyses = $run->analyses_for_sample($regex);
        if ( not $run_analyses ) {
            $self->warning_message("No analyses found for library name %s on run %", $library_name, $run->__name__);
            next;
        }
        push @analyses, @$run_analyses;
    }
    $self->_analyses(\@analyses);
}

sub execute {
    my ($self) = @_;

    $self->__init__;

    for my $analysis ( @{$self->_analyses} ) {
        my $bam = $self->_bam_output_for_analysis($analysis);
        next if $bam and -s $bam;
        my $cmd = $self->_bax_to_bam_command_for_analysis($analysis);
        $self->_commands_fh->print("$cmd\n");
    }

    $self->_commands_fh->close if $self->commands_file ne '-';
    1;
}

sub _bam_output_for_analysis {
    my ($self, $analysis) = @_;
    return if not $self->bam_output_directory;
    # m151026_060206_00116_c100928752550000001823208204291687_s1_p0.subreads.bam
    # m151026_060206_00116_c100928752550000001823208204291687_s1_p0.bax.h5
    my @bax_files = map { $_->stringify } grep { "$_" =~ /\.bax\.h5$/ } @{$analysis->analysis_files};
    my @bax_basenames = List::Util::uniq( 
        map { my $bn = $_->basename; my ($t) = split(/\./, $bn, 2); $t; } grep { "$_" =~ /\.bax\.h5$/ } sort @{$analysis->analysis_files}
    );
    $self->fatal_message('Expected one BAX file basename: %s', join(' ', @bax_basenames)) if @bax_basenames != 1;
    $self->_bam_output_directory->file( join('.', $bax_basenames[0], 'subreads', 'bam') );
}

sub _bax_to_bam_command_for_analysis {
    my ($self, $analysis) = @_;

    my @bax_files = sort { $a cmp $b } map { $_->stringify } grep { "$_" =~ /\.bax\.h5$/ } @{$analysis->analysis_files};
    $self->fatal_message('Incorrect number (%d) of BAX files for run analysis: %s', scalar(@bax_files), $analysis->alias) if not @bax_files or @bax_files != 3;

    # bsub -o /dir/%LOG bax2bam -o %OUT_BAM BAX_FILES
    my $cmd = $self->bam_to_bax_command;

    my $log_rex = qr/%LOG/;
    if ( $cmd =~ /$log_rex/ ) {
        my $log = join('.', $analysis->alias, 'out');
        $cmd =~ s/$log_rex/$log/;
    }

    join(' ', $cmd, join(' ', @bax_files));
}

1;
