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

1;
