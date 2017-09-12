package Refimp::Project;

use strict;
use warnings;

use File::Path;
use File::Spec;
use Params::Validate qw( :types validate_pos );
use Refimp::Project::NotesFile;
use Refimp::Resources::LimsRestApi;

class Refimp::Project {
    table_name => 'projects',
    id_generator => '-uuid',
    id_by => {
        id => { is => 'Text', },
    },
    has => {
        name => { is => 'Text', doc => 'Name of the project.', },
    },
    has_optional => {
        directory => { is => 'Text', doc => 'File system location.', },
        status => { is => 'Text', doc => 'Current status of the project.', },
        clone_type => {
            is => 'Text',
            valid_values => [
                "bac", "chromosome", "cosmid", "fosmid", "fosmid library", "genome", "pac", "unknown", "yac",
            ],
            doc => 'Clone type: bac, cosmid, etc.',
        },
        my_status => {
            is => 'Text',
            via => 'project_finishers',
            to => 'status',
        },
        # Taxonomy
        taxonomy => {
            is => 'Refimp::Project::Taxonomy',
            reverse_as => 'project',
        },
        taxon => {
            is => 'Refimp::Taxon',
            via => 'taxonomy',
            to => 'taxon',
        },
    },
    has_many => {
        # Prefinishers
        project_users => {
            is => 'Refimp::Project::User',
            reverse_as => 'project',
            doc => 'Project user links.',
        },
        prefinishers => {
            is => 'Refimp::User',
            via => 'project_users',
            where => [qw/ purpose prefinisher /],
            to => 'user',
            doc => 'Project prefinishers user object.',
        },
        prefinisher_unix_logins => {
            via => 'prefinishers',
            to => 'unix_login',
            doc => 'Project prefinisher unix logins.',
        },
        # Finishers
        project_finishers => {
            is => 'Refimp::Project::User',
            reverse_as => 'project',
            where => [qw/ purpose finisher /],
            doc => 'Project finishers bridge object',
        },
        finishers => {
            is => 'Refimp::User',
            via => 'project_users',
            where => [qw/ purpose finisher /],
            to => 'user',
            doc => 'Project finisher user objects.',
        },
        finisher_unix_logins => {
            via => 'finishers',
            to => 'unix_login',
            doc => 'Project finisher unix logins.',
        },
        # Saver
        savers => {
            is => 'Refimp::User',
            via => 'project_users',
            where => [qw/ purpose saver /],
            to => 'user',
            doc => 'Project saver objects.',
        },
        saver_unix_logins => {
            via => 'saver',
            to => 'unix_login',
            doc => 'Project saver unix logins.',
        },
        # Submissions
        submissions => {
            is => 'Refimp::Project::Submission',
            reverse_as => 'project',
        }
    },
    data_source => Refimp::Config::get('ds_mysql'),
};

sub __display_name__ { sprintf('%s (%s)', $_[0]->name, $_[0]->id) }

sub sub_directory_names { (qw/ chromat_dir digest edit_dir phd_dir /) }
sub chromat_directory { $_[0]->subdir_for('chromat_dir'); }
sub digest_directory { $_[0]->subdir_for('digest'); }
sub edit_directory { $_[0]->subdir_for('edit_dir'); }
sub phd_directory { $_[0]->subdir_for('phd_dir'); }
sub subdir_for {
    my ($self, $subdir) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});
    return File::Spec->join($self->directory, $subdir);
}

sub directory {
    my ($self, $value) = @_;
    if ( not defined $value ) {
        return $self->__directory if $self->__directory;
        return File::Spec->join( Refimp::Config::get('seqmgr'), $self->name );
    }
    $self->fatal_message('Directory to set does not exist! %s', $value) if not -d $value;
    $self->__directory($value);
    $self->create_project_directory_structure;
}

sub create_project_directory_structure {
    my $self = shift;

    my $directory = $self->directory;
    $self->fatal_message('No directory for proejct: %s', $self->__display_name__) if not $directory;
    $self->fatal_message('Project directory does not exist: %s', $directory) if not -d $directory;

    for my $sub_dir_name ( $self->sub_directory_names ) {
        my $sub_dir = File::Spec->join($directory, $sub_dir_name);
        next if -d $sub_dir;
        File::Path::mkpath($sub_dir);
        $self->fatal_message('Failed to make sub directory: %s', $sub_dir) if not -d $sub_dir;
    }

    return $directory;
}

sub notes_file_path { File::Spec->join($_[0]->directory, $_[0]->name.'.notes'); }
sub notes_file { Refimp::Project::NotesFile->new($_[0]->notes_file_path); }

1;
