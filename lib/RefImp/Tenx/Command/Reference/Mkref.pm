package RefImp::Tenx::Command::Reference::Mkref;

use strict;
use warnings;

use Cwd qw( chdir cwd );
use File::Slurp;
use File::Temp 'tempfile';
use Path::Class;
use IPC::Open3;

use RefImp::Tenx::Reference;
my %inputs = map {
    $_->property_name => {
        is => $_->data_type,
        doc => $_->doc,
    }
} map {
    RefImp::Tenx::Reference->__meta__->property_meta_for_name($_) 
} (qw/ name taxon /);

class RefImp::Tenx::Command::Reference::Mkref { 
    is => 'RefImp::Tenx::Command::LongrangerBase',
    has_input => {
        %inputs,
        fasta_file => {
            is => 'Text',
            doc => 'Fasta to run mkref on.',
        },
    },
    has_optional_constant_calculated => {
        output_directory => {
            calculate_from => [qw/ _fasta_file /],
            calculate => q| $_fasta_file->parent |,
        },
        reference_directory => {
            calculate_from => [qw/ _fasta_file output_directory /],
            calculate => q|
                my $fasta_file_basename = $_fasta_file->basename;
                $fasta_file_basename =~ s/\.\w+$//;
                $output_directory->subdir('refdata-'.$fasta_file_basename);
            |,
        },
        _fasta_file => {
            calculate_from => [qw/ fasta_file /],
            calculate => q| Path::Class::file($fasta_file) |,
        },
    },
    doc => 'run longranger mkref and make reference db entry',
};

sub help_detail {
<<HELP;
Run mkref on a fasta to make a longranger compatible reference.

Output refence files are stored in the directory thatthis command is run in!

HELP
}

sub _validate_pre_tenx_command {
    my $self = shift;

    $self->status_message('Reference Mkref...');
    my $reference = RefImp::Tenx::Reference->get(name => $self->name);
    $self->fatal_message('Reference for %s already exists: %s', $self->name, $reference->__display_name__) if $reference;
    $self->fatal_message('Fasta file %s does not exist!', $self->fasta_file) if not -s $self->_fasta_file->stringify;
}

sub _tenx_command {
    my $self = shift;
    (qw/ longranger mkref /, $self->_fasta_file->stringify );
}

sub _validate_post_tenx_command {
    my $self = shift;
    # Check for in out file: Reference successfully created
    #
    $self->status_message('Reference directory: %s', $self->output_directory->stringify);
    $self->fatal_message('Output mkref directory does not exist!') if not -d $self->output_directory->stringify;
}

sub _create_db_entities {
    my $self = shift;
    RefImp::Tenx::Command::Reference::Create->execute(
        name => $self->name,
        directory => $self->reference_directory->stringify,
        taxon => $self->taxon,
    );
}

1;
