package RefImp::Cron::Command::UpdateAccessionsFromReports;

use strict;
use warnings;

use Cwd 'cwd';
use File::Temp 'tempdir';
use List::MoreUtils 'firstval';
use RefImp::Resources::NcbiFtp;

class RefImp::Cron::Command::UpdateAccessionsFromReports {
    is => 'Command::V2',
    doc => 'update project accesssion number form ncbi reports',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message('Update accession numbers from NCBI...');

    my $ftp = RefImp::Resources::NcbiFtp->connect;
    $ftp->cwd('REPORT');

    my $cwd = cwd();
    my $working_dir = tempdir(CLEANUP => 1);
    $self->status_message("CWD: $cwd");
    $self->status_message("Entering local working dir: $working_dir");
    chdir $working_dir;

    my @failed_projects;
    my @files = grep { m/fa2htgs.asn.ac4htgs$/ } $ftp->ls;
    $self->status_message("Found %s report files...", scalar(@files));
    for my $file ( @files ) {
        $self->status_message("Checking file: %s", $file);
        $ftp->get($file);
        my $report = RefImp::Resources::Ncbi::SubmissionReport->from_file($file);
        $self->fatal_message('Failed to create report from file: %s', $file) if not $report;
        if ( not $report->update_submission ) {
            push @failed_projects, $report->project_name;
        }
        else {
            $self->status_message("UPDATE project %s submission accession to %s", $report->{project}->__display_name__, $report->submission->accession_id);
        }
    }
    chdir $cwd;

    $self->fatal_message('Failed to update these projects: %s', join(' ', @failed_projects)) if @failed_projects;
    $self->status_message('Update accession numbers from NCBI...OK');
    return 1;
}

1;
