package Pacbio::Run::Command::PrepareSubmission;

use strict;
use warnings 'FATAL';

use Digest::MD5;
use File::Path;
use IO::File;
use List::Util;
use Path::Class;
use Pacbio::Run::SRAXML::PrimaryAnalysis;
use Util::Tablizer;
use Pacbio::Run;

class Pacbio::Run::Command::PrepareSubmission {
    is => 'Command::V2',
    has => {
        biosample => {
            is => 'Text',
            doc => 'Biosample for the submission.',
        },
        bioproject  => {
            is => 'Text',
            doc => 'Bioproject for the submission.',
        },
        machine_type => {
            is => 'Text',
            valid_values => [ Pacbio::Run->valid_machine_types ],
            doc => 'Machine type for run: '.join(' ', Pacbio::Run->valid_machine_types),
        },
        output_path  => {
            is => 'Text',
            doc => 'Directory for run file links and XMLs.'
        },
        sample_name => {
            is => 'Text',
            doc => "The sample name to use in submission XMLs.",
        },
        library_name => {
            is => 'Text',
            doc => "The library name to match when collecting a run's analysis files.",
        },
        run_directories => {
            is => 'Text',
            is_many => 1,
            doc => "The file paths containing the analysis files.",
        },
        submission_alias  => {
            is => 'Text',
            doc => 'An alias for the submission.'
        },
    },
    has_transient_optional => {
        runs => { is => 'ARRAY', },
        analyses => { is => 'ARRAY', },
    },
    doc => 'bundle pacbio runs for submit',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message("Pac Bio Prepare Run for Submit...");
    File::Path::make_path($self->output_path) if not -d $self->output_path;
    $self->get_pacbio_runs;
    $self->get_analyses_from_runs;
    $self->link_analysis_files_to_output_path;
    $self->render_xml;
    $self->status_message("Pac Bio Prepare Run for Submit...DONE");
    1;
}

sub get_pacbio_runs {
    my ($self) = @_;

    my @runs;
    for my $directory ( $self->run_directories ) {
        push @runs, Pacbio::Run->new(
            directory => dir($directory),
            machine_type => $self->machine_type,
        );

    }
    $self->fatal_message('No runs to submit!') if not @runs;

    $self->runs(\@runs);
}

sub get_analyses_from_runs {
    my ($self) = @_;
    $self->status_message('Gathering analyses from runs...');

    my $library_name = $self->library_name;
    my $regex = qr/$library_name/;

    my @analyses;
    my @rows = ( [ 'Run', 'Total', "$library_name", ] );
    for my $run ( @{$self->runs} ) {
        my $sample_analyses = $run->analyses_for_sample($regex);
        if ( not $sample_analyses ) {
            $self->fatal_message('Did not find analyses for %s on run %s!', $library_name, $run->directory);
        }
        push @rows, [ $run->directory, $run->analyses_count, scalar(@$sample_analyses) ];
        push @analyses, @$sample_analyses;
    }
    $self->fatal_message('No analyses found for any pac bio runs!') if not @analyses;

    $self->status_message('Run analyses and sample anaylese counts');
    $self->status_message( Util::Tablizer->format(\@rows) );

    $self->status_message('Found %s total analyses for %s', scalar(@analyses), $library_name);
    #my $max = List::Util::max( map { -s $_ } @analyses);
    #$self->status_message('Largest file [Kb]: %.0d', ($max/1024));

    $self->status_message('Gathering analyses from runs...DONE');
    $self->analyses(\@analyses);
}

sub link_analysis_files_to_output_path {
    my ($self) = @_;
    $self->status_message('Linking analysis files...');

    my $output_path = dir( $self->output_path );
    for my $analysis ( @{$self->analyses} ) {
        for my $file ( @{$analysis->analysis_files}, $analysis->metadata_xml_file ) {
            my $dest_basename = $file->basename;
            $dest_basename =~ s/^\.//;
            my $link = $output_path->file($dest_basename);
            symlink("$file", "$link")
                or $self->fatal_message('Failed to link %s to %s', $file, $link);
        }
    }

    $self->status_message('Linking analysis files...DONE');
}

sub render_xml {
    my $self = shift;
    $self->status_message("Rendering submission XML...");

    # name is library_name from the LIMS DB and does not match the metadata xml
    # H_IJ-HG02818-HG02818_1-lib2 VS 4808lj_HG02818_Lib2_50pM_A1
    my $analyses = $self->analyses;
    my $meta = {
        library_name => $self->sample_name,
        bioproject => $self->bioproject,
        biosample => $self->biosample,
        instrument => 'PacBio RS II',
        version => ( sort( List::Util::uniq( map { $_->version } @$analyses ) ) )[0],
        library_strategy => 'WGS',
        library_source => 'GENOMIC',
        library_selection => 'unspecified',
        library_layout => 'single',
        run_data => [], # data_blocks below
    };

    my @v;
    for my $analysis ( @$analyses ) {
        $self->status_message('Preparing analysis: %s', $analysis->__name__);

        my $data_block = {
            alias => $analysis->alias,
            files => [],
        };
        push @{$meta->{run_data}}, $data_block;

        for my $file ( sort(@{$analysis->analysis_files}), $analysis->metadata_xml_file ) {
            my $ctx = Digest::MD5->new;
            $ctx->addfile( IO::File->new("$file", 'r') );

            my $basename = $file->basename;
            $basename =~ s/^\.//;
            push @{$data_block->{files}}, {
                checksum => $ctx->hexdigest,
                type => $self->type_for_file($file),
                file => $basename,
            };
         }
    }

    my $da = Pacbio::Run::SRAXML::PrimaryAnalysis->new(
        data => [$meta],#$struct,
        submission_alias  => $self->submission_alias,
    );

    my @xml = $da->render_sra_xml();
    Pacbio::Run::SRAXML->write_tar_file_to_dir(
        dir  => $self->output_path,
        name => $self->submission_alias,
        xml  => \@xml,
    );

    $self->status_message("Rendering submission XML...DONE");
}

sub type_for_file {
    my ($self, $file) = @_;
    $self->fatal_message('No file given to get type!') if not $file;

    my @tokens = split(/\./, $file->basename);
    return 'PacBio_HDF5' if $tokens[$#tokens] eq 'h5';
    return 'bam' if $tokens[$#tokens] eq 'xml' and $self->machine_type eq 'sequel';
    $tokens[$#tokens];
}

1;
