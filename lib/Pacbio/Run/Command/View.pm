package Pacbio::Run::Command::View;

use strict;
use warnings 'FATAL';

use Path::Class;
use Pacbio::Run;
use YAML;

class Pacbio::Run::Command::View {
    is => 'Command::V2',
    has => {
        machine_type => {
            is => 'Text',
            valid_values => [ Pacbio::Run->valid_machine_types ],
            doc => 'Machine type for run: '.join(' ', Pacbio::Run->valid_machine_types),
        },
        run_directory => {
            is => 'Text',
            shell_args_position => 1,
            doc => "The file path containing the run and analysis files.",
        },
    },
    doc => 'show info about a run',
};

sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    my $run = Pacbio::Run->new(
        directory => dir($self->run_directory),
        machine_type => $self->machine_type,
    );
    my $analyses = $run->analyses;
    $self->fatal_message('No analyses found for run!') if not $analyses;
    for my $analysis ( @$analyses ) {
        my %to_dump = map { $_ => $analysis->$_ } (qw/ library_name plate_id well /);
        $to_dump{metadata_xml_file} = $analysis->metadata_xml_file->stringify;
        $to_dump{analysis_files} = [ map { "$_" } @{$analysis->analysis_files} ];
        print YAML::Dump(\%to_dump);
    }

    1;
}

1;
