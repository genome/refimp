package RefImp::Assembly::Submission;

use strict;
use warnings 'FATAL';

use File::Spec;
use File::Slurp;
use Path::Class;
use Set::Scalar;
use YAML;
use RefImp::Assembly::SubmissionInfo;

class RefImp::Assembly::Submission {
   data_source => RefImp::Config::get('refimp_ds'),
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
        accession_id => { is => 'Text', len => 32, },
        bioproject_uid => { is => 'Text', via => 'ncbi_biosample', to => 'bioproject_uid', },
        biosample_uid => { is => 'Text', via => 'ncbi_biosample', to => 'biosample_uid', },
        directory => { is => 'Text', doc => 'Submission directory', },
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
		tar_basename => {
            is => 'Text',
            calculate_from => [qw/ ncbi_version submitted_on /],
            calculate => q|
                my ($date) = split(' ', $submitted_on);
                $ncbi_version.'_'.$date.'.tar';
            |,
        },
   },
   has_optional_transient => {
        submission_info => { is => 'HASH', },
        ncbi_biosample => { is => 'RefImp::Resources::Ncbi::Biosample', },
   },
   doc => 'Assembly submission record',
};

sub __display_name__ { sprintf('%s %s submitted on %s part of %s %s', map { defined($_) ? $_ : 'NA' } ($_[0]->id, $_[0]->version, $_[0]->submitted_on, $_[0]->bioproject, $_[0]->biosample)) }

sub get {
    my $class = shift;

    my $self = $class->SUPER::get(@_);
    return if not $self;

    if ( $self->submission_yml ) {
        my $info = YAML::Load($self->submission_yml);
        $self->fatal_message('Failed to parse submission YAML!') if not $info;
        $self->submission_info($info);
    }

    $self;
}

sub get_or_create_from_yml {
    my $class = shift;
    $class->_from_yml(@_);
}

sub get_or_define_from_yml {
    my $class = shift;
    $class->_from_yml(@_, '__define__');
}

sub _from_yml {
    my ($class, $yml, $instantiation_method) = @_;

    $instantiation_method //= 'create';

    $class->fatal_message('No submission YAML given!') if not $yml;
    $class->fatal_message('Submission YAML does not exist! %s', $yml) if not -s $yml;
    $yml = Path::Class::file($yml);
    my $info = YAML::LoadFile($yml);
    $class->fatal_message('Failed to open submission YAML!') if not $info;

    $class->fatal_message('No unique_id in submission yml! ,Pleasese use \'refimp assembly submission add-unique-id\' to correct in YAML file.') if not $info->{unique_id};
    $class->fatal_message('Invalid unique_id in YAML: %s. Please use \'refimp assembly submission add-unique-id\' to correct in YAML file.', $info->{unique_id}) if $info->{unique_id} !~ /[A-Z0-9]{32}/;
    my $id = $info->{unique_id};
    my $self = $class->get($id);
    return $self if $self;

    $class->fatal_message('No taxon in submission YAML! %s', $yml) if not $info->{taxon};
    my $taxon = RefImp::Taxon->get(species_name => lc $info->{taxon});
    $class->fatal_message('Taxon not found for "%s"!', $info->{taxon}) if not $taxon;

    my $directory = $yml->dir->absolute;
    my $assembly_id = UR::Object::Type->autogenerate_new_object_id_uuid;
    my $assembly = RefImp::Assembly->$instantiation_method( # for now, just create a new assembly for each submission
        id => $assembly_id,
        name => $assembly_id, # gotta be unique
        taxon => $taxon, # only thing we really know
        tech => 'unknown', # FIXME pass this in
        url => "$directory", # submission dir, assembly is somewhere nearby
    );

    my %params = map { $_ => $info->{$_} // undef } (qw/ biosample bioproject version /);
    $params{assembly} = $assembly,
    $params{directory} = "$directory";
    $params{id} = $id;
    $params{submission_info} = $info;
    $params{submission_yml} = YAML::Dump($info);
    if ( $params{biosample} and $params{bioproject} ) {
        $params{ncbi_biosample} = RefImp::Resources::Ncbi::Biosample->create(
            bioproject => $params{bioproject},
            biosample => $params{biosample},
        );
    }

    $class->$instantiation_method(%params);
}

sub add_info_for {
    my ($self, $key, $value) = @_;
    $self->fatal_message('No submission info set!') if not $self->submission_info;
    $self->fatal_message('No key given to add submission info!') if not $key;
    $self->fatal_message('No value given to add submission info!') if not defined $value;
    $self->submission_info->{$key} = $value
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

    my $nonfile_keys = Set::Scalar->new( grep { $_ !~ /_file$/ } RefImp::Assembly::SubmissionInfo->submission_info_keys );
    my $optional_keys = Set::Scalar->new( RefImp::Assembly::SubmissionInfo->submission_info_optional_keys );
    for my $key ( $nonfile_keys->difference($optional_keys)->members ) {
        $self->fatal_message('No %s in submission info!', $key) if not defined $self->info_for($key);
    }

    RefImp::Assembly::Command::Submission::CreateTar->format_names( $self->info_for('authors') );
    my @formatted_contact = RefImp::Assembly::Command::Submission::CreateTar->format_names( $self->info_for('contact') );
    $self->fatal_message('More than one contact found in submission info!') if @formatted_contact > 1;

    1;
}

1;
