package RefImp::Assembly::Submission;

use strict;
use warnings 'FATAL';

use Path::Class;
use File::Spec;
use File::Slurp;
use Set::Scalar;
use YAML;

class RefImp::Assembly::Submission {
   data_source => RefImp::Config::get('ds_mysql'),
   table_name => 'assemblies_submissions',
   id_generator => '-uuid',
   id_by => {
        id => { is => 'Text', column_name => 'submission_id', },
   },
   has => {
        assembly => { is => 'RefImp::Assembly', id_by => 'assembly_id', doc => 'Assembly being submitted', },
        biosample => { is => 'Text', doc => 'NCBI biosample', },
        bioproject => { is => 'Text', doc => 'NCBI bioproject', },
        submitted_on => { is => 'Date', default_value => UR::Context->now, doc => 'The date of submission', },
        taxon => { via => 'assembly', to => 'taxon', doc => 'Assembly taxon', },
        version => { is => 'Text', doc => 'Numbered assembly version', },
   },
   has_optional => {
        bioproject_uid => { is => 'Text', via => 'ncbi_biosample', to => 'bioproject_uid', },
        biosample_uid => { is => 'Text', via => 'ncbi_biosample', to => 'biosample_uid', },
        directory => { is => 'Text', doc => 'Submission directory', },
        project_title => { is => 'Text', via => 'ncbi_biosample', to => 'project_title', },
        submission_yml => { is => 'Text', doc => 'YAML with submission information', },
   },
   has_optional_calculated => {
        ncbi_version => {
            is => 'Text',
            calculate_from => [qw/ taxon version /],
            calculate => q|
                my @species_name_tokens = split(/\s+/, $taxon->species_name);
                join('_', ucfirst($species_name_tokens[0]), @species_name_tokens[1..$#species_name_tokens], $version);
            |,
        },
   },
   has_optional_transient => {
        submission_info => { is => 'HASH', },
        ncbi_biosample => { is => 'RefImp::Resources::Ncbi::Biosample', },
   },
   doc => 'Assembly submission record',
};

sub __display_name__ { sprintf('%s %s submitted on %s part of %s %s', $_[0]->id, $_[0]->version, $_[0]->submitted_on, $_[0]->bioproject, $_[0]->biosample) }

sub default_release_date { (__PACKAGE__->valid_release_dates)[0] }
sub valid_release_dates { ( 'immediately after processing', 'hold until publication', '\d{2}-\d{2}-\d{4}' ) }
sub valid_release_date_regexps { map { qr/^$_$/ } valid_release_dates() }

sub create_from_yml {
    my ($class, $yml) = @_;

     $class->fatal_message('No submission YAML given!') if not $yml;
     $class->fatal_message('Submission YAML does not exist! %s', $yml) if not -s $yml;
     $yml = Path::Class::file($yml);
     my $info = YAML::LoadFile($yml);
     $class->fatal_message('Failed to open submission YAML!') if not $info;

     $class->fatal_message('No taxon in submission YAML! %s', $yml) if not $info->{taxon};
     my $taxon = RefImp::Taxon->get(species_name => lc $info->{taxon});
     $class->fatal_message('Taxon not found for "%s"!', $info->{taxon}) if not $taxon;

     my $directory = $yml->dir->absolute;
     my $id = UR::Object::Type->autogenerate_new_object_id_uuid;
     my $assembly = RefImp::Assembly->create( # for now, just create a new assembly for each submission
         id => $id,
         name => $id, # gotta be unique
         taxon => $taxon, # only thing we really know
         directory => "$directory", # submission dir, assembly is somewhere nearby
     );

     my %params = map { $_ => $info->{$_} // undef } (qw/ biosample bioproject version /);
     $params{assembly} = $assembly,
     $params{directory} = "$directory";
     $params{submission_info} = $info;
     $params{submission_yml} = YAML::Dump($info);

     $class->create(%params);
}

sub info_for {
    my ($self, $key) = @_;
    $self->fatal_message('No submission info set!') if not $self->submission_info;
    $self->fatal_message('No key given to get submission info!') if not $key;
    $self->submission_info->{$key};
}

sub path_for {
    my ($self, $key) = @_;

    $self->fatal_message('No submission directory!') if not $self->directory;
    $self->fatal_message('Submission directory does not exist!') if not -d $self->directory;

    my $file_name = $self->info_for($key);
    return if not $file_name;

    my $file = File::Spec->join($self->directory, $file_name);
    $self->fatal_message('File %s is defined in submission info, but does not exist! %s', $key, $file) if not -s $file;
    $file;
}

sub release_notes {
    my $self = shift;
    my $release_notes_file = $self->path_for('release_notes_file');
    $self->fatal_message('Release notes file does not exist! %s', $release_notes_file) if not -s $release_notes_file;
    File::Slurp::slurp($release_notes_file);
}

sub validate_for_submit {
    my $self = shift;

    $self->fatal_message('No directory set to validate submission!') if not $self->directory;
    $self->fatal_message('Failed to validate for submit, submission directory (%s) does not exist!', $self->directory) if not -d $self->directory;

    my $info = $self->submission_info;
    $self->fatal_message('No submission info set!') if not $info or not %$info;

    my $assembly_method = $self->info_for('assembly_method');
    $self->fatal_message('Invalid assembly_method "%s", a "v." is required between the assembler and the date run/version.', $assembly_method) if $assembly_method !~ / v\. /;


    # Verify bioproject/biosample
    my $ncbi_biosample = RefImp::Resources::Ncbi::Biosample->create(
        bioproject => $self->bioproject,
        biosample => $self->biosample,
    );
    $self->ncbi_biosample($ncbi_biosample);

    # Release notes is required
    $self->fatal_message('No release_notes_file in submission info!') if not $self->info_for('release_notes_file');
    $self->path_for('release_notes_file'); # fatal if not defined and existing

    # Contigs/Supercontigs/AGP
    my $contigs_file = $self->path_for('contigs_file');
    my $supercontigs_file = $self->path_for('supercontigs_file');
    my $agp_file = $self->path_for('agp_file');
    if ( $supercontigs_file ) {
        $self->fatal_message('Both contigs and supercontigs files are defined in submission info, but can only specify one!') if $contigs_file;
        $self->fatal_message('Supercontigs cannot have an AGP file!') if $agp_file;
    }
    elsif ( not $contigs_file ) { # no contigs, no supercontigs
        $self->fatal_message('No contigs or supercontigs files set in submission YAML!');
    }

    my $nonfile_keys = Set::Scalar->new( grep { $_ !~ /_file$/ } RefImp::Assembly::Command::Submission::Yaml->submission_info_keys );
    my $optional_keys = Set::Scalar->new( RefImp::Assembly::Command::Submission::Yaml->submission_info_optional_keys );
    for my $key ( $nonfile_keys->difference($optional_keys)->members ) {
        $self->fatal_message('No %s in submission info!', $key) if not defined $self->info_for($key);
    }

    1;
}

1;
