package RefImp::Assembly::Command::Submission::Email;

use strict;
use warnings 'FATAL';

class RefImp::Assembly::Command::Submission::Email {
    is => 'Command::V2',
    has_input => {
        submission => {
            is => 'RefImp::Assembly::Submission',
            doc => 'Submission record to generate email.',
            shell_args_position => 1,
        },
    },
    doc => 'show the email for an assembly submission',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub __errors__ {
    my $self = shift;

    my @errors = $self->SUPER::__errors__;

    if ( @errors ) {
        $self->fatal_message( join("\n", map { $_->__display_name__ } @errors) );
    }

    @errors;
}

sub execute {
    my $self = shift;

    my $submission = $self->submission;
    my $bioproject = $submission->bioproject;
    my $biosample = $submission->biosample;
    my $species_name = ucfirst $submission->taxon->species_name;

    my $subject = sprintf(
        "New '%s' [%s %s] Assembly Submission",
        $species_name,
        $bioproject,
        $biosample,
    );

	my $to = 'genomes@ncbi.nlm.nih.gov';
	my $submission_email = 'mgi-submission@gowustl.onmicrosoft.com';
    my $strain_name = $submission->taxon->strain_name || 'NA';
    my $release_date = $submission->info_for('release_date');
    my $tar_file = $submission->tar_basename;

    my $msg = <<MSG;
To: $to
Cc: $submission_email
From: $submission_email
Message:
Greetings!

The McDonnell Genome Institute has submitted a new assembly
from the BioSample $biosample of BioProject $bioproject to GenBank.

  Organism Name: $species_name
  Strain: $strain_name
  Release Date: $release_date

Please find $tar_file on ftp-private.ncbi.nlm.nih.gov

Sincerely,
MGI Submissions <$submission_email>
MSG

    print $msg;
}

1;
