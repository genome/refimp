package RefImp::Assembly::Submission;

use strict;
use warnings 'FATAL';

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
        submission_yml => { is => 'Text', doc => 'YAML file with submission information', },
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

    $class->SUPER::create(%params);
}

sub info_for {
    my ($self, $key) = @_;
    $self->fatal_message('No key given to get submission info!') if not $key;
    $self->submission_info->{$key};
}

sub validate_for_submit {
    my $self = shift;

    my $info = $self->submission_info;
    $self->fatal_message('No submission info set!') if not $info or not %$info;

    my $esummary = RefImp::Resources::Ncbi::EsummaryBiosample->create(biosample => $self->biosample);
    $self->fatal_message('Bioproject given does not match that found linked to biosample! %s <=> %s', $self->bioproject, $esummary->bioproject) if $self->bioproject ne $esummary->bioproject;
    for my $key (qw/ agp_file contigs_file supercontigs_file /) {
        my $file = $info->{$key};
        $self->fatal_message('No %s in submission info!', $key) if not $file;
        $self->fatal_message('File %s in submission info not exist! %s', $key, $file) if not -s $file;
    }

    1;
}

1;
