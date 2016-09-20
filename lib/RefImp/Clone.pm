package RefImp::Clone;

use strict;
use warnings;

use RefImp;

use RefImp::Clone::NotesFile;
use RefImp::Clone::Taxon;

use File::Spec;
use Params::Validate qw( :types validate_pos );
use RefImp::Resources::LimsRestApi;

=doc 2016-03-15

CLONES	GSC::Clone	oltp	production

     CHR_CHROMOSOME      chromosome          VARCHAR2(8)           (fk)    
   x CLO_ID              clo_id              NUMBER(15)            (pk)(fk)
     CLONE_DATE_RECEIVED clone_date_received DATE(19)                      
     CLONE_EXTENSION     clone_extension     VARCHAR2(4)  NULLABLE         
   x CLONE_NAME          clone_name          VARCHAR2(64)          (unique)
     CLOPRE_CLONE_PREFIX clone_prefix        VARCHAR2(16)                  
     CLONE_SIZE          clone_size          VARCHAR2(16)                  
   x CS_CLONE_STATUS     clone_status        VARCHAR2(64)          (fk)    
   x CT_CLONE_TYPE       clone_type          VARCHAR2(25)          (fk)    
     GAP                 gap                 VARCHAR2(2)  NULLABLE         
     MAP_LOCATION        map_location        VARCHAR2(64) NULLABLE         
     MAP_ORDER           map_order           VARCHAR2(64)                  

=cut

class RefImp::Clone {
    table_name => 'clones',
    id_by => {
        id => { is => 'Integer', column_name => 'clo_id', },
    },
    has => {
        name => { is => 'Text', column_name => 'clone_name', doc => 'Name of the clone.', },
        status => { is => 'Text', column_name => 'cs_clone_status', doc => 'Status of the clone.', },
        type => { is => 'Text', column_name => 'ct_clone_type', doc => 'Clone type: bac, cosmid, etc.', },
    },
    has_calculated_constant => {
        project => {
            calculate_from => [qw/ name /],
            calculate => q{ RefImp::Project->get(name => $name) },
        },
        project_status => {
            calculate_from => [qw/ project /],
            calculate => q{ $project->status },
            doc => 'Status of the project: finish_start, submitted, etc.',
        },
    },
    data_source => RefImp::Config::get('ds_oltp'),
};

sub __display_name__ { sprintf('%s (%s)', $_[0]->name, $_[0]->id) }

sub taxonomy {
    my ($self, $attribute) = @_;
    return $self->{_taxonmy} if $self->{taxonomy};
    my %taxonomy;
    for my $attribute (qw/ species_name species_latin_name chromosome /) {
        $taxonomy{$attribute} = RefImp::Resources::LimsRestApi->new->query($self, $attribute);
    }
    return $self->{_taxonmy} = RefImp::Clone::Taxon->create(%taxonomy);
}
sub species_name { $_[0]->taxonomy->species_name }
sub species_latin_name { $_[0]->taxonomy->species_latin_name }
sub chromosome { $_[0]->taxonomy->chromosome }

sub project_directory {
    my ($self) = validate_pos(@_, {type => OBJECT, isa => __PACKAGE__});
    return $self->project_directory_for_name($self->name);
}

sub project_directory_for_name {
    my ($self, $name) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    my $seqmgr_link = File::Spec->join( RefImp::Config::get('seqmgr'), $name );
    return $seqmgr_link if -d $seqmgr_link;
    return;
}

sub notes_file_path { File::Spec->join($_[0]->project_directory, $_[0]->name.'.notes'); }
sub notes_file { RefImp::Clone::NotesFile->new($_[0]->notes_file_path); }

sub ace0_path {
    my $self = shift;

    my $project_directory = $self->project_directory;
    return if not -d $project_directory;

    my @exts = (qw/ fasta screen /);
    while ( @exts ) {
        my $ace0 = File::Spec->join($project_directory, 'edit_dir', join('.', $self->name, @exts, 'ace', '0'));
        return $ace0 if -s $ace0;
        pop @exts;
    }

    return;
}

1;

