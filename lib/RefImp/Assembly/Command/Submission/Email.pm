package RefImp::Assembly::Command::Submission::Email;

use strict;
use warnings 'FATAL';

class RefImp::Assembly::Command::Submission::Email {
    is => 'Command::V2',
    has_optional_input => {
        submission => {
                is => 'RefImp::Assembly::Submission',
        },
        submission_yml => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'YAML file with submission info. It must be in the assembly submission directory. Use the "refimp assembly submission yaml" command for a template or help (--h).',
        },
    },
    doc => 'show the email for an assembly submission',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;

	my $to = 'genomes@ncbi.nlm.nih.gov';
	my $submission_email = 'mgi-submission@gowustl.onmicrosoft.com';

    my $submission = $self->_resolve_submission;
    my $bioproject = $submission->bioproject;
    my $biosample = $submission->biosample;
    my $species_name = ucfirst $submission->taxon->species_name;

    my $subject = sprintf(
        "New '%s' [%s %s] Assembly Submission",
        $species_name,
        $bioproject,
        $biosample,
    );

    my $strain_name = $submission->taxon->strain_name || 'NA';
    my $release_date = $submission->info_for('release_date');
    #my $tar_file = $self->tar_file->basename;
    my $tar_file = 'tar';

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

sub _resolve_submission {
    my $self = shift;

    my $submission = $self->submission;
    return $submission if $submission;

    if ( not $self->submission_yml ) {
        $self->fatal_message('No submission or submission_yml given!');
    }

    $submission = RefImp::Assembly::Submission->define_from_yml($self->submission_yml);
    $self->fatal_message('Failed to define Subimssion from yml file! %s', $self->submission_yml) if not $submission;

    $self->submission($submission);
}

1;
