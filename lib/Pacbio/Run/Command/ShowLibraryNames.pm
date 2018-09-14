package Pacbio::Run::Command::ShowLibraryNames;

use strict;
use warnings 'FATAL';

use Path::Class;
use Pacbio::Run;
use Util::Tablizer;
use YAML;

class Pacbio::Run::Command::ShowLibraryNames {
    is => 'Command::V2',
    has => {
        machine_type => {
            is => 'Text',
            valid_values => [ Pacbio::Run->valid_machine_types ],
            doc => 'Machine type for run: '.join(' ', Pacbio::Run->valid_machine_types),
        },
        run_directory=> {
            is => 'Text',
            shell_args_position => 1,
            doc => "The file path containing the run and analysis files.",
        },
    },
    has_optional => {
        library_name => {
            is => 'Text',
            default_value => '.',
            doc => 'The library name to match in the analysis metadata.',
        },
    },
    doc => "show a run's library names and check if the pattern given matches"
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    my $run = Pacbio::Run->new(
        directory => dir($self->run_directory),
        machine_type => $self->machine_type,
    );
    my $analyses = $run->analyses;
    if ( not $analyses ) {
        $self->error_message('No analyses or files found! Is diectory and machine_type correct?');
        return;
    }

    my $library_name = $self->library_name;
    my $library_name_qr = qr/$library_name/;
    my $match_count = 0;
    my @rows = ( [qw/ well sample_name matches? /] );
    for my $analysis ( @$analyses ) {
        my $match = 'no';
        if ( $analysis->library_name =~ $library_name_qr ) {
            $match = 'yes';
            $match_count++;
        }
        push @rows, [$analysis->well, $analysis->library_name, $match ];
    }

    printf(
        "Run: %s\nLibrary Name: %s\nAnalyses:\n%sAnalyses Total: %s\nMatched Analyses: %s\n",
        $run->__name__, $library_name, Util::Tablizer->format(\@rows), scalar(@$analyses), $match_count,
    );

    1;
}

1;
