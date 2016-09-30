package RefImp::Project;

use strict;
use warnings;

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
    PRIORITY                 priority                 NUMBER(1)                      
  x PROJECT_ID               project_id               NUMBER(10)             (pk)    
  x PROSTA_PROJECT_STATUS    project_status           VARCHAR2(22)           (fk)    
    PP_PURPOSE               purpose                  VARCHAR2(32)           (fk)    
    SPANNED_GAP              spanned_gap              NUMBER(10)    NULLABLE         
    SPANNED_GSC_GAP          spanned_gsc_gap          NUMBER(10)    NULLABLE         
    TARGET                   target                   NUMBER(5)                      

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
        status => { is => 'Text', column_name => 'prosta_project_status', },
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

sub directory {
    my ($self, $value) = @_;
    if ( not defined $value ) {
        return $self->__directory if $self->__directory;
        return File::Spec->join( RefImp::Config::get('seqmgr'), $self->name );
    }
    $self->fatal_message('Directory to set does not exist! %s', $value) if not -d $value;
    return $self->__directory($value);
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

