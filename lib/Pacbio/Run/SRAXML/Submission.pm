package Pacbio::Run::SRAXML::Submission;

use strict;
use warnings 'FATAL';

use Moose;
extends 'Pacbio::Run::SRAXML';

has 'xml'   => (is => 'ro',required => 1,isa => 'ArrayRef');
has 'alias' => (is => 'ro',required => 1,isa => 'Str');

sub data_struct {
    my $self = shift;

    my @actions;
    for my $xml_string (@{$self->xml}) {
        my $sub_type = lc($self->get_xml_basenode_name($xml_string));
        $sub_type =~ s/_set//g;

        my $add = {
            ACTION => {
                ADD => {
                    source => $self->alias .'.' .$sub_type .'.xml',
                    schema => $sub_type,
                }
            },
        };
        push(@actions,$add);
    }

    my $struct = {
        seq_SUBMISSION => {
            SUBMISSION => {
                alias => $self->alias,
                center_name => 'WUGSC',
                CONTACTS => {
                    seq_CONTACT => {
                        CONTACT => {name => 'LIMS',
                                    inform_on_status => 'mailto:mgi-submission@gowustl.onmicrosoft.com',
                                    inform_on_error  => 'mailto:mgi-submission@gowustl.onmicrosoft.com',
                        }
                    },
                },
                ACTIONS => {
                    seq_ACTION => [
                        {
                            ACTION => {
                                RELEASE => {}
                            },
                        },
                        @actions,
                    ],
                },
            },
        }
    };
    return $struct;
}

1;
