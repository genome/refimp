package RefImp::Assembly::Submission;

use strict;
use warnings 'FATAL';

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
};

sub default_release_date { (__PACKAGE__->valid_release_dates)[0] }
sub valid_release_dates { ( 'immediately after processing', 'hold until publication', '\d{2}-\d{2}-\d{4}' ) }
sub valid_release_date_regexps { map { qr/^$_$/ } valid_release_dates() }

1;
