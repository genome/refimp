package RefImp::Project::Submission;

use strict;
use warnings;

use Date::Format;
use File::Path 'make_path';

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

1;
