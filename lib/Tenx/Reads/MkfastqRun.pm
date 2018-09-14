package Tenx::Reads::MkfastqRun;

use strict;
use warnings;

use IO::File;
use List::MoreUtils;
use Path::Class;
use Params::Validate qw/ :types validate_pos /;
use Text::CSV;

class Tenx::Reads::MkfastqRun { 
    has => {
        directory => { is => 'Path::Class::Dir', },
        samplesheet => { is => 'Tenx::Reads::SampleSheet', },
        lanes => { via => 'samplesheet', to => 'lanes', },
        samples => { via => 'samplesheet', to => 'samples', },
        sample_names => { via => 'samplesheet', to => 'sample_names', },
    },
    has_optional => {
        project_name => { is => 'Text', },
    },
    doc => 'sample sheet for running mkfastq and creating reads db entries',
};

sub create {
    my ($class, $directory) = validate_pos(@_, {is => __PACKAGE__}, {is => SCALAR});

    $directory = dir($directory);
    $class->fatal_message('Mkfastq directory given does not exist: %s', $directory) if !-d "$directory";

    my $file = $directory->subdir('outs')->file('input_samplesheet.csv');
    $class->fatal_message('No samplesheet found in mkfastq directory: %s', $file) if !-s "$file";

    my $samplesheet = Tenx::Reads::SampleSheet->create($file);

    my $project_name;
    my $invocation_file = $directory->file('_invocation');
    if ( -s "$invocation_file" ) {
        $project_name = $class->get_project_from_invocation($invocation_file);
    }

    my %params = (
        directory => $directory,
        samplesheet => $samplesheet,
    );
    $params{project_name} = $project_name if $project_name;

    $class->SUPER::create(%params);
}

sub get_project_from_invocation {
    my ($class, $invocation_file) = validate_pos(@_, {is => __PACKAGE__}, {is => SCALAR});

    my $fh = IO::File->new($invocation_file, 'r');
    $class->fatal_message('Failed to open: %s', $invocation_file) if not $fh;
    my $project;
    while ( my $line = $fh->getline ) {
        next if $line !~ /project\s+=\s+"(.+)"/;
        $project = $1;
        last;
    }
    $fh->close;

    $project;
}

sub fastq_directory_for_sample_name {
    my ($self, $sample_name) = validate_pos(@_, {is => __PACKAGE__}, {is => SCALAR});

    # Fastq Finder
    my $has_fastqs = sub{
        my $fq_dir = shift;
        return if not -d "$fq_dir";
        my $fq_pattern = $fq_dir->file('*.fastq*');
        my @fastq_files = glob("$fq_pattern");
        return @fastq_files;
    };

    # Check sample /
    my $directory = $self->directory;
    my $sample_directory = $directory->subdir($sample_name);
    return $sample_directory if $has_fastqs->($sample_directory);

    # Check in the project directories
    my @project_names = List::MoreUtils::uniq map { $_->{project} } grep { defined $_->{project} and $_->{name} eq $sample_name } @{$self->samples};
    unshift @project_names, $self->project_name if $self->project_name;
    for my $project_name ( @project_names ) {
        # Check project / sample
        $sample_directory = $directory->subdir($project_name)->subdir($sample_name);
        return $sample_directory if $has_fastqs->($sample_directory);
        # Check outs / fastq_path / project / sample
        $sample_directory = $directory->subdir('outs')->subdir('fastq_path')->subdir($project_name)->subdir($sample_name);
        return $sample_directory if $has_fastqs->($sample_directory);
    }

    $self->fatal_message('Could not find fastqs for sample: %s', $sample_name);
}

1;
