package RefImp::Pacbio::Command::CheckLibraryNameOnRun;

use strict;
use warnings 'FATAL';

use Path::Class;
use RefImp::Pacbio::Run;
use RefImp::Util::Tablizer;
use YAML;

class RefImp::Pacbio::Command::CheckLibraryNameOnRun {
    is => 'Command::V2',
    has => {
        machine_type => {
            is => 'Text',
            valid_values => [ RefImp::Pacbio::Run->valid_machine_types ],
            doc => 'Machine type for run: '.join(' ', RefImp::Pacbio::Run->valid_machine_types),
        },
        library_name => {
            is => 'Text',
            doc => 'The library name to match in the analysis metadata.',
        },
        run_directory=> {
            is => 'Text',
            shell_args_position => 1,
            doc => "The file path containing the run and analysis files.",
        },
    },
    doc => 'check a library name',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    my $run = RefImp::Pacbio::Run->new(
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
        if ( $analysis->sample_name =~ $library_name_qr ) {
            $match = 'yes';
            $match_count++;
        }
        push @rows, [$analysis->well, $analysis->sample_name, $match ];
    }

    $self->status_message('Run: %s', $run->__name__);
    $self->status_message('Library Name: %s', $library_name);
    $self->status_message("Analyses:\n%s", RefImp::Util::Tablizer->format(\@rows));
    $self->status_message('Analyses Total: %s', scalar(@$analyses));
    $self->status_message('Matched Analyses: %s', $match_count);

    1;
}

1;
