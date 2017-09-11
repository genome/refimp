package Refimp::Resources::Ncbi::SubmissionReport;

use strict;
use warnings;

use IO::File;
use Params::Validate qw/ :types validate_pos /;
use Refimp::Resources::Ncbi::ProjectName;

class Refimp::Resources::Ncbi::SubmissionReport {
    is => 'UR::Object',
    has => {
        project => { is => 'Refimp::Project', },
        project_name => { is => 'Text', },
        data => { is => 'HASH', },
        submission => { is => 'Refimp::Project::Submission', },
    },
};

sub create {
    my ($class, %data) = @_;

    my $self = $class->SUPER::create(data => \%data);
    return if not $self;

    my $project_name = $self->data->{localseqname};
    $self->project_name($project_name);

    my $project = Refimp::Project->get(name => $project_name);
    if ( $project ) {
        $self->project($project);
        my @submissions = Refimp::Project::Submission->get(
            project => $project,
            phase => $self->data->{phase},
            -order => 'submitted_on',
        );
        # Use the lastest submission
        $self->submission( $submissions[$#submissions] ) if @submissions;
    }

    $self;
}

sub update_submission {
    my $self = shift;
    $self->error_message('No project for %s', $self->data->{localseqname}) and return if not $self->project;
    $self->error_message('No submission for %s', $self->project->__display_name__) and return if not $self->submission;
    $self->submission->accession_id($self->data->{accession});
}

sub from_file {
    my ($class, $file) = validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});

    my $fh = IO::File->new($file, 'r');
    die "Failed to open $file" if not $fh;

    my %data = ( file => $file );
    while ( my $line = $fh->getline ) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        my ($key, $value) = split(': ', $line, 2);
        next if not defined $value;
        $data{$key} = $value;
    }
    $fh->close;

    $data{localseqname} = Refimp::Resources::Ncbi::ProjectName->ncbi_to_local($data{seqname});

    my ($accession, $version) = split(/\./, delete $data{accession});
    $version //= 1;
    $data{accession} = $accession;
    $data{version} = $version;

    $class->create(%data);
}

1;
