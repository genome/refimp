package RefImp::Project;

use strict;
use warnings;

use File::Path;
use File::Spec;
use Params::Validate qw( :types validate_pos );
use RefImp::Project::NotesFile;
use RefImp::Resources::LimsRestApi;

=doc 2016-05-03

PROJECTS	GSC::Project	oltp	production

    APROX_COVERAGE           aprox_coverage           NUMBER(126)   NULLABLE
    ARCHIVAL_DATE            archival_date            DATE(19)      NULLABLE
  x CONSENSUS_DIRECTORY      consensus_directory      VARCHAR2(150) NULLABLE
    DATE_LAST_ASSEMBLED      date_last_assembled      DATE(19)      NULLABLE
    ESTIMATED_SIZE           estimated_size           NUMBER(126)   NULLABLE
    ESTIMATED_SIZE_FROM_CTGS estimated_size_from_ctgs NUMBER(8)     NULLABLE
    GRO_GROUP_NAME           group_name               VARCHAR2(64)  NULLABLE
  x NAME                     name                     VARCHAR2(64)           (unique)
    NO_ASSEMBLE_TRACES       no_assemble_traces       NUMBER(126)   NULLABLE
    NO_CONTIGS               no_contigs               NUMBER(126)   NULLABLE
    NO_CT_GT_1KB             no_ct_gt_1kb             NUMBER(126)   NULLABLE
    NO_Q20_BASES             no_q20_bases             NUMBER(126)   NULLABLE
  x PRIORITY                 priority                 NUMBER(1)
  x PROJECT_ID               project_id               NUMBER(10)             (pk)
  x PROSTA_PROJECT_STATUS    project_status           VARCHAR2(22)           (fk)
  x PP_PURPOSE               purpose                  VARCHAR2(32)           (fk)
    SPANNED_GAP              spanned_gap              NUMBER(10)    NULLABLE
    SPANNED_GSC_GAP          spanned_gsc_gap          NUMBER(10)    NULLABLE
  x  TARGET                   target                   NUMBER(5)

=cut

class RefImp::Project {
    table_name => 'projects',
    id_by => {
        id => { is => 'Integer', column_name => 'project_id', },
    },
    has => {
        name => { is => 'Text', doc => 'Name of the project.', },
    },
    has_optional => {
        directory => { is => 'Text', column_name => 'consensus_directory', doc => 'File system location.', },
        priority => { is => 'Number', len => 1, doc => 'Legacy project priority.', },
        purpose => { is => 'Text', column_name => 'pp_purpose', doc => 'Legacy project purpose.', },
        status => { is => 'Text', column_name => 'prosta_project_status', },
        target => { is => 'Number', len => 5, doc => 'Legacy project target.', },
    },
    has_many => {
        status_histories => {
            is => 'RefImp::Project::StatusHistory',
            reverse_as => 'project',
            where => [ -order_by => '-status_date' ],
            doc => 'Time stamped statuses of this project.',
        },
        # Prefinishers
        claimed_as_prefinishers => {
            is => 'RefImp::Project::Prefinisher',
            reverse_as => 'project',
            doc => 'Project prefinisher links.',
        },
        prefinishers => {
            is => 'RefImp::User',
            via => 'claimed_as_prefinishers',
            to => 'user',
            doc => 'Project prefinishers user object.',
        },
        prefinisher_unix_logins => {
            via => 'prefinishers',
            to => 'unix_login',
            doc => 'Project prefinisher unix logins.',
        },
        # Finishers
        claimed_as_finishers => {
            is => 'RefImp::Project::Finisher',
            reverse_as => 'project',
            doc => 'Project finisher links.',
        },
        finishers => {
            is => 'RefImp::User',
            via => 'claimed_as_finishers',
            to => 'user',
            doc => 'Project finisher user objects.',
        },
        finisher_unix_logins => {
            via => 'finishers',
            to => 'unix_login',
            doc => 'Project finisher unix logins.',
        },
        # Saver
        claimed_as_savers => {
            is => 'RefImp::Project::Saver',
            reverse_as => 'project',
            doc => 'Project saver links.',
        },
        savers => {
            is => 'RefImp::User',
            via => 'claimed_as_savers',
            to => 'user',
            doc => 'Project saver objects.',
        },
        saver_unix_logins => {
            via => 'saver',
            to => 'unix_login',
            doc => 'Project saver unix logins.',
        },
    },
    data_source => RefImp::Config::get('ds_oltp'),
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
        return File::Spec->join( RefImp::Config::get('seqmgr'), $self->name );
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

sub status {
    my ($self, $value) = @_;
    return $self->__status if not defined $value;
    RefImp::Project::StatusHistory->create(project => $self, project_status => $value);
    return $self->__status;
}

sub notes_file_path { File::Spec->join($_[0]->directory, $_[0]->name.'.notes'); }
sub notes_file { RefImp::Project::NotesFile->new($_[0]->notes_file_path); }

1;

