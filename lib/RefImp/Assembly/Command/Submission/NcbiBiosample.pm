package RefImp::Assembly::Command::Submission::NcbiBiosample;

use strict;
use warnings 'FATAL';

use RefImp::Resources::Ncbi::Biosample;
use Util::Tablizer;

class RefImp::Assembly::Command::Submission::NcbiBiosample { 
    is => 'Command::V2',
    has_input => {
        bioproject => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'NCBI bioproject.',
        },
        biosample => {
            is => 'Text',
            shell_args_position => 2,
            doc => 'NCBI biosample.',
        },
    },
    has_param => {
        verify => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Test the NCBI bioproject/bioproject link.',
        },
    },
    doc => 'check NCBI bioproject/sample',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my ($self) = @_;

    my $biosample = RefImp::Resources::Ncbi::Biosample->create(
        bioproject => $self->bioproject,
        biosample => $self->biosample,
    );

    my @output;
    for (qw/ bioproject bioproject_uid biosample biosample_uid elink_url /) {
        push @output, [ $_, $biosample->$_ ];
    }
    if ( $self->verify ) {
        push @output, [ 'verify', $biosample->verify ];
        #$biosample->elink_xml
    }

    $self->status_message( Util::Tablizer->format(\@output) );
    1;
}

1;
