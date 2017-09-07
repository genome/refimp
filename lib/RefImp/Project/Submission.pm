package RefImp::Project::Submission;

use strict;
use warnings;

use Date::Format;
use File::Basename 'basename';
use File::Path 'make_path';
use File::Spec;
use RefImp::Config;
use Storable 'retrieve';

use Params::Validate qw/ :types validate_pos /;
class RefImp::Project::Submission {
    table_name => 'projects_submissions',
    #id_generator => '-uuid',
    #id_by => {
    #    id => { is => 'Text', },
    #},
    id_by => {
        project_id => { is => 'Text', },
        submitted_on => { is => 'DateTime', },
    },
    has => {
        phase => { is => 'Text', },
        project => { is => 'RefImp::Project', id_by => 'project_id', },
    },
    has_optional => {
        accession_id => { is => 'Text', },
        directory => { is => 'Text', },
        project_size => { is => 'Number', },
    },
    data_source => RefImp::Config::get('ds_mysql'),
};

sub __display_name__ {
    return sprintf('%s (%s) on %s (%s)', $_[0]->project->name, ($_[0]->accession_id || 'NA'), $_[0]->submitted_on, ($_[0]->directory || 'NA'));
}

sub create {
    my ($class, %params) = @_;

    $params{submitted_on} = Date::Format::time2str(q|%Y-%m-%d|, time()) if not $params{submitted_on};

    my $self = $class->SUPER::create(%params);
    return if not $self;

    $self->directory( $self->new_submission_directory ) if not $self->directory;

    $self;
}

sub create_from_directory {
    my ($class, $directory) = @_;

    $class->fatal_message('No directory specified to create submission record from!') if not $directory;
    $class->fatal_message('Directory to create submission record from does not exist!') if not -d $directory;

    my %params = (
        directory => $directory,
        phase => 3,
    );
    my $date = basename($directory);
    if ( $date =~ /^\d{8}$/ ) {
        substr $date, 4, 0, '-';
        substr $date, 7, 0, '-';
        $params{submitted_on} = $date;
    }

    my $submit_info;
    my ($yml_file) = glob( File::Spec->join($directory, '*.submit.yml') );
    if ( $yml_file ) {
        #VMRC59-197N17.submit.yml
        $submit_info = YAML::LoadFile($yml_file);
    }
    else {
        #H_NH0094P19.serialized.dat
        my ($serialized_dot_dat) = glob( File::Spec->join($directory, '*.serialized.dat') );
        $submit_info = retrieve($serialized_dot_dat) if $serialized_dot_dat;
    }

    $class->fatal_message('Cannot create submission record from directory because there is no submit info in %s', $directory) if not $submit_info;

    my $project_name = $submit_info->{GENINFO}->{CloneName};
    my $project = RefImp::Project->get(name => $project_name);
    $class->fatal_message('Failed to get project for %s', $project_name) if not $project;
    $params{project} = $project;

    if ( exists $submit_info->{GENINFO}->{CloneAccession} ) {
        $params{accession_id} = $submit_info->{GENINFO}->{CloneAccession};
    }

    if ( exists $submit_info->{COMMENTS}->{ContigData} ) {
        for ( @{$submit_info->{COMMENTS}->{ContigData}} ) { $params{project_size} += $_->{ContigFinishedTo} - $_->{ContigFinishedFrom} + 1; }
    }

    $class->create(%params);
}

sub new_submission_directory {
    my $self = shift;

    my ($date_stamp) = split(/\s+/, $self->submitted_on, 2);
    $date_stamp =~ s/\-//g;
    my $directory = File::Spec->join(
        RefImp::Config::get('analysis_directory'),
        $self->project->taxon->species_short_name,
        lc( $self->project->name ),
        $date_stamp,
    );

    $self->fatal_message('Project submission directory (%s) already exists!', $directory) if -d $directory;

    make_path($directory)
        or $self->fatal_message('Failed to make new analysis subdirectory for %s', $self->project->__display_name__);

    $directory
}

# Sequence Files
sub sequence_file_name {
    join('.', $_[0]->project->name, 'seq');
}

sub whole_contig_file_name { # includes transposons
    join('.', $_[0]->project->name, 'whole', 'contig');
}

# Submit Form
sub submit_form_file_name {
    join('.', $_[0]->project->name, 'submit', 'form');
}

sub submit_form_file {
    File::Spec->join($_[0]->directory, $_[0]->submit_form_file_name);
}

sub legacy_submit_form_file {
    File::Spec->join($_[0]->directory, 'README');
}

sub submit_info_yml_file_name {
    join('.', $_[0]->project->name, 'submit', 'yml');
}

sub submit_info_stor_file_name {
    join('.', $_[0]->project->name, 'serialized', 'dat');
}

sub raw_sqn_template_for_taxon {
    my ($class, $taxon) = validate_pos(@_, {isa => __PACKAGE__}, {isa => 'RefImp::Taxon'});
    my $raw_template_path = File::Spec->join(
        RefImp::Config::get('analysis_directory'),
        'templates',
        join('_', 'raw', $taxon->species_short_name, 'template'),
    );
    $raw_template_path .= '.sqn';
    return $raw_template_path;
}

1;
