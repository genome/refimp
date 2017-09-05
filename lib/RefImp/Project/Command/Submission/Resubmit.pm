package RefImp::Project::Command::Submission::Resubmit;

use strict;
use warnings 'FATAL';

use File::Copy;
use File::Copy::Recursive;
use File::Temp;
use Path::Class;
use RefImp::Resources::NcbiFtp;
use YAML;

class RefImp::Project::Command::Submission::Resubmit { 
    is => 'Command::V2',
    has => {
        from_submission => {
            is => 'RefImp::Project::Submission',
            doc => 'Submission to resubmit.',
        },
    },
    has_transient_optional => {
        asn_path => { is => 'Text', },
        staging_directory => { is => 'Path::Class::Dir', },
        submit_info => { is => 'Text', },
        submission => { is => 'RefImp::Project::Submission', },
    },
    doc => 'REsubmit a project to NCBI',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;

    $self->_setup;
    $self->_copy_submission_files;
    $self->_load_submit_info;
    $self->_generate_asn;
    $self->_ftp_asn_to_ncbi;
    $self->_copy_staging_content_to_submission_directory;
    $self->_update_project_and_submission;

    return 1;
}

sub _setup {
    my $self = shift;

    $self->staging_directory( dir( File::Temp::tempdir(CLEANUP => 1)) );
    chmod(0775, $self->staging_directory->stringify);
    $self->status_message('Staging directory: %s', $self->staging_directory);

    $self->submission(
        RefImp::Project::Submission->create(
            project => $self->from_submission->project,
            phase => 3,
        )
    ) or $self->fatal_message('Failed to create submission record for %s', $self->project->__display_name__);
    $self->status_message('Submission record: %s', $self->submission->__display_name__);
}

sub _copy_submission_files {
    my $self = shift;
    $self->status_message('Copy submission files...');

    my $from_submission = $self->from_submission;
    my $from_dir = dir( $from_submission->directory );
    my $submission = $self->submission;
    for my $method (qw/ submit_info_yml_file_name sequence_file_name /) {
        my $from_file = $from_dir->file($from_submission->$method);
        my $file = $self->staging_directory->file($submission->$method);
        $self->status_message('Copy %s to %s', $from_file, $file);
        if ( not File::Copy::copy($from_file->stringify, $file->stringify) ) {
            $self->fatal_message('Failed to copy %s file from submission to staging directory: %s', $method, $!);
        }
        if ( not -s $file->stringify ) {
            $self->fatal_message('Copy succeeded, but file does not exist! %s', $file)
        }
    }

    $self->status_message('Copy submission files...OK');
}

sub _load_submit_info {
    my $self = shift;
    $self->status_message('Load submit info...');

    my $submit_file = $self->staging_directory->file($self->submission->submit_info_yml_file_name);
    $self->submit_info( YAML::LoadFile($submit_file->stringify) );

    $self->status_message('Load submit info...OK');
}

sub _generate_asn {
    my $self = shift;
    $self->status_message('Generate ASN...');

    my $asn = RefImp::Project::Submission::Asn->create(
        project => $self->submission->project,
        submit_info => $self->submit_info,
        working_directory => $self->staging_directory->stringify,
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
    my $ncbi_file_name = join('.', $self->submission->project->name, 'phase3', 'fa2htgs', 'asn');
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

sub _copy_staging_content_to_submission_directory {
    my $self = shift;
    $self->status_message('Copy contents of staging directory to submission directory...');

    $self->status_message('Staging directory: %s', $self->staging_directory);
    $self->status_message('Submission directory: %s', $self->submission->directory);
    my $rv = File::Copy::Recursive::dircopy($self->staging_directory->stringify, $self->submission->directory);
    if ( not $rv ) {
        $self->fatal_message('Failed to copy staging directory to submission directory! %s', $!);
    }

    $self->status_message('Copy contents of staging directory to submission directory...OK');
}

sub _update_project_and_submission {
    my $self = shift;
    $self->status_message('Project status: %s', $self->submission->project->status('submitted'));
    my $size = 0;
    for ( @{$self->submit_info->{COMMENTS}->{ContigData}} ) { $size += $_->{ContigFinishedTo} - $_->{ContigFinishedFrom} + 1; }
    $self->status_message('Project size: %s', $self->submission->project_size($size));
}

1;
