package RefImp::Assembly::Submission;

use strict;
use warnings 'FATAL';

use File::Basename;
use File::Spec;
use File::Slurp;
use Set::Scalar;
use YAML;

class RefImp::Assembly::Submission {
   doc => 'Assembly submission record',
   #data_source => RefImp::Config::get('ds_mysql'),
   #table_name => 'assemblies_submissions',
   id_generator => '-uuid',
   has => {
        biosample => { is => 'Text', doc => 'NCBI biosample', },
        bioproject => { is => 'Text', doc => 'NCBI bioproject', },
        submitted_on => { is => 'Date', default_value => UR::Context->now, doc => 'The date of submission', },
        version => { is => 'Text', doc => 'NCBI formatted assembly version', },
   },
   has_optional => {
        bioproject_uid => { is => 'Text', via => 'esummary', to => 'bioproject_uid', },
        biosample_uid => { is => 'Text', via => 'esummary', to => 'biosample_uid', },
        directory => { is => 'Text', doc => 'Submission directory', },
        submission_yml => { is => 'Text', doc => 'YAML file with submission information', },
   },
   has_optional_calculated => {
        esummary => {
            is => 'RefImp::Resources::Ncbi::EsummaryBiosample',
            is_constant => 1,
            calculate_from => [qw/ biosample /],
            calculate => q| RefImp::Resources::Ncbi::EsummaryBiosample->create(biosample => $biosample) |,
        },
   },
   has_optional_transient => {
        submission_info => { is => 'HASH', },
   },
};

sub default_release_date { (__PACKAGE__->valid_release_dates)[0] }
sub valid_release_dates { ( 'immediately after processing', 'hold until publication', '\d{2}-\d{2}-\d{4}' ) }
sub valid_release_date_regexps { map { qr/^$_$/ } valid_release_dates() }

sub create_from_yml {
    my ($class, $yml) = @_;

     $class->fatal_message('No submission YAML given!') if not $yml;
     $class->fatal_message('Submission YAML does not exist! %s', $yml) if not -s $yml;
     my $info = YAML::LoadFile($yml);
     $class->fatal_message('Failed to open submission YAML!') if not $info;

    my %params = map { $_ => $info->{$_} // undef } (qw/ biosample bioproject version /);
    $params{submission_info} = $info;
    $params{submission_yml} = $yml;
    $params{directory} = File::Basename::dirname($yml);

    $class->SUPER::create(%params);
}

sub info_for {
    my ($self, $key) = @_;
    $self->fatal_message('No submission info set!') if not $self->submission_info;
    $self->fatal_message('No key given to get submission info!') if not $key;
    $self->submission_info->{$key};
}

sub release_notes {
    my $self = shift;

    $self->fatal_message('No submission directory!') if not $self->directory;
    $self->fatal_message('Submission directory does not exist!') if not -d $self->directory;

    my $release_notes_file_name = $self->info_for('release_notes_file');
    $self->fatal_message('No release notes file in submission info!') if not $release_notes_file_name;

    my $release_notes_file = File::Spec->join($self->directory, $release_notes_file_name);
    $self->fatal_message('Release notes file does not exist! %s', $release_notes_file) if not -s $release_notes_file;

    File::Slurp::slurp($release_notes_file);
}

sub validate_for_submit {
    my $self = shift;

    $self->fatal_message('No directory set to validate submission!') if not $self->directory;
    $self->fatal_message('Failed to validate for submit, submission directory (%s) does not exist!', $self->directory) if not -d $self->directory;

    my $info = $self->submission_info;
    $self->fatal_message('No submission info set!') if not $info or not %$info;

    my $esummary = $self->esummary;
    $self->fatal_message('Bioproject given does not match that found linked to biosample! %s <=> %s', $self->bioproject, $esummary->bioproject) if $self->bioproject ne $esummary->bioproject;

    my $info_keys = Set::Scalar->new( RefImp::Assembly::Command::SubmissionYaml->submission_info_keys );
    my $file_keys = Set::Scalar->new( grep { /_file$/ } $info_keys->members );
    for my $key ( $file_keys->members ) {
        my $file_name = $info->{$key};
        $self->fatal_message('No %s in submission info!', $key) if not $file_name;
        my $file = File::Spec->join($self->directory, $file_name);
        $self->fatal_message('File %s in submission info not exist! %s', $key, $file) if not -s $file;
    }

    my $nonfile_keys = $info_keys->difference($file_keys);
    for my $key ( $nonfile_keys ) {
        $self->fatal_message('No %s in submission info!', $key) if not defined $info->{$key};
    }

    # TODO
    # check contigs/supercontigs names are in agp

    1;
}

1;
