package RefImp::Project::Command::Submit;

use strict;
use warnings;

use Bio::SeqIO;
use File::Basename;
use File::Copy::Recursive;
use File::Spec;
use File::Temp;
use IO::File;
use Net::FTP;
use RefImp::Ace::Directory;
use RefImp::Project::Submissions;
use RefImp::Project::Submissions::Info;
use RefImp::Project::Submissions::Form;
use RefImp::Project::Submissions::Sequence;
use RefImp::Resources::NcbiFtp;
use YAML;

class RefImp::Project::Command::Submit { 
    is => 'RefImp::Project::Command::QaBase',
    has_transient_optional => {
        analysis_subdirectory => { is => 'Text', },
        asn_path => { is => 'Text', },
        staging_directory => { is => 'Text', },
        submit_info => { is => 'Text', },
    },
    doc => 'submit a project to NCBI',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub valid_project_statuses { (qw/ presubmitted submitted /) }

sub execute {
    my $self = shift;

    $self->_check_project_status;
    $self->_generate_submit_info;
    $self->_save_submit_form;
    $self->_save_sequence;
    $self->_generate_asn;
    $self->_ftp_asn_to_ncbi;
    $self->_move_staging_content_to_analysis_subdirectory;
    $self->_update_project_status;

    return 1;
}

sub _generate_submit_info {
    my $self = shift;
    $self->status_message('Generate submit info...');

    $self->staging_directory( File::Temp::tempdir(CLEANUP => 1) );
    chmod(0775, $self->staging_directory);
    $self->status_message('Staging directory: %s', $self->staging_directory);

    $self->status_message('Load submit info...');
    $self->submit_info( RefImp::Project::Submissions::Info->generate($self->project) );

    my $file = File::Spec->join(
        $self->staging_directory, RefImp::Project::Submissions->submit_info_yml_file_name_for_project($self->project),
    );
    $self->status_message('Save submit YAML: %s', $file);
    YAML::DumpFile($file, $self->submit_info);

    $self->status_message('Generate submit info...OK');
}

sub _save_submit_form {
    my $self = shift;
    $self->status_message('Save submit form...');

    my $form = RefImp::Project::Submissions::Form->create($self->submit_info)
        or die 'Failed to generate submissions form!';
    my $file = File::Spec->join(
        $self->staging_directory,
        RefImp::Project::Submissions->submit_form_file_name_for_project($self->project),
    );
    $self->status_message('Submit form path: %s', $file);
    my $fh = IO::File->new($file, 'w')
        or die "Failed to open submit form file ($file): $!";
    $fh->print($form);
    $fh->close;

    $self->status_message('Save submit form...OK');
}

sub _save_sequence {
    my $self = shift;

    my $acedir = RefImp::Ace::Directory->create(project => $self->project);
    my $ace0_file = $acedir->ace0_file;
    die "No ace.0 for ".$self->project->name if not $ace0_file;

    my %seq_params = (
        clone_name => $self->project->name,
        ace => $ace0_file,
        contig_data => $self->submit_info->{COMMENTS}->{ContigData},
    );
    if ( $self->submit_info->{COMMENTS}->{TransposonComments} ) {
        $seq_params{transposons} = $self->submit_info->{COMMENTS}->{TransposonComments};
    }
    my $sequence = RefImp::Project::Submissions::Sequence->create(%seq_params);

    my $io = Bio::SeqIO->new(
        -file => '>'.File::Spec->join($self->staging_directory, join('.', $self->project->name, 'whole', 'contig')),
        -format => 'Fasta',
    );
    $io->write_seq($sequence->seq);
    $io->close;

    my $transposon_excised_seq = $sequence->transposon_excised_seq;
    $io = Bio::SeqIO->new(
        -file => '>'.File::Spec->join($self->staging_directory, join('.', $self->project->name, 'seq')),
        -format => 'Fasta',
    );
    $io->write_seq($transposon_excised_seq);
    $io->close;
}

sub _generate_asn {
    my $self = shift;
    $self->status_message('Generate ASN...');

    my $asn = RefImp::Project::Submissions::Asn->create(
        project => $self->project,
        submit_info => $self->submit_info,
        working_directory => $self->staging_directory,
    );
    $asn->generate;

    $self->asn_path( $asn->asn_path );
    $self->status_message('Generate ASN...OK');
}

sub _ftp_asn_to_ncbi {
    my $self = shift;
    $self->status_message('FTP ASN to NCBI...');

    my $ftphost = RefImp::Config::get('ncbi_ftp_host');
    $self->status_message('FTP host: %s', $ftphost);
    my $ftp = RefImp::Resources::NcbiFtp->connect;
    $ftp->cwd('SEQSUBMIT');

    my $asn_path = $self->asn_path;
    $self->status_message('ASN path: %s', $asn_path);
    my $asn_file_name = File::Basename::basename($asn_path);
    my $asn_path_size = -s $asn_path;
    $self->status_message('ASN size: %s', $asn_path_size);
    my $ncbi_file_name = join('.', $self->project->name, 'phase3', 'fa2htgs', 'asn');
    $self->status_message('Remote file name: %s', $ncbi_file_name);

    if ( not $ftp->put($asn_path, $ncbi_file_name) ) {
        $self->fatal_message('FTP::put failed!');
    }
    my $ncbi_size = $ftp->size($ncbi_file_name);
    if ( not $ncbi_size ) {
        $self->fatal_message('FTP::put succeeded, but file has no size!');
    }
    elsif ( $ncbi_size != $asn_path_size ) {
        $self->fatal_message('FTP::put succeeded, but file was only partially uploaded!');
    }

    $self->status_message('FTP ASN to NCBI...OK');
}

sub _update_project_status {
    my $self = shift;
    $self->status_message('Set project status...');

    my $psh = RefImp::Project::StatusHistory->create(
        project => $self->project,
        project_status => 'submitted',
    );

    $self->status_message('Project status: %s', $self->project->status);
}

sub _move_staging_content_to_analysis_subdirectory {
    my $self = shift;
    $self->status_message('Copy contents of staging directory to analysis subdirectory...');

    $self->status_message('Staging directory: %s', $self->staging_directory);
    my $analysis_subdirectory = $self->analysis_subdirectory(
        RefImp::Project::Submissions->new_analysis_subdirectory_for_project($self->project)
    );
    $self->status_message('Analysis subdirectory: %s', $analysis_subdirectory);
    my $rv = File::Copy::Recursive::dircopy($self->staging_directory, $analysis_subdirectory)
        or $self->fatal_message('Failed to copy contents! '.$!);

    $self->status_message('Copy contents of staging directory to analysis subdirectory...OK');
}

1;

