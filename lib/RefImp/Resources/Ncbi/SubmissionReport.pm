package RefImp::Resources::Ncbi::SubmissionReport;

use strict;
use warnings;

use File::Basename 'basename';
use IO::File;
use Params::Validate qw/ :types validate_pos /;

class RefImp::Resources::Ncbi::SubmissionReport {
    is => 'UR::Object',
    has => {
        project => { is => 'RefImp::Project', },
        report => { is => 'HASH', },
        submission => { is => 'RefImp::Project::Submission', },
    },
};

sub create {
    my ($class, %report) = @_;

    my $self = $class->SUPER::create(report => \%report);
    return if not $self;

    my $project = RefImp::Project->get(name => $self->report->{localseqname});
    if ( $project ) {
        $self->project($project);
        my @submissions = RefImp::Project::Submission->get(
            project => $project,
            phase => $self->report->{phase},
            -order => 'submitted_on',
        );
        # Use the lastest submission
        $self->submission( $submissions[$#submissions] ) if @submissions;
    }

    $self;
}

sub update_submission {
    my $self = shift;
    $self->fatal_message('No project for %s', $self->report->{localseqname}) if not $self->project;
    $self->fatal_message('No submission for %s', $self->project->__display_name__) if not $self->submission;
    $self->submission->accession_id($self->report->{accession});
}

sub from_file {
    my ($class, $file) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    my $fh = IO::File->new($file, 'r');
    die "Failed to open $file" if not $fh;

    my %report = ( file => $file );
    while ( my $line = $fh->getline ) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        my ($key, $value) = split(': ', $line, 2);
        next if not defined $value;
        $report{$key} = $value;
    }
    $fh->close;

    my $file_name = basename($file);
    my @file_name_tokens = split(/\./, $file_name);
    $report{localseqname} = $file_name_tokens[1];

    my ($accession, $version) = split(/\./, delete $report{accession});
    $version //= 1;
    $report{accession} = $accession;
    $report{version} = $version;

    $class->create(%report);
}

1;
