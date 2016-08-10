package RefImp::Project::Command::Makecon;

use strict;
use warnings;

use Try::Tiny qw( try catch );
use GetSeq;
use Findid::Utility;

class RefImp::Project::Command::Makecon {
    is => 'RefImp::Project::Command::Base',
    has_input => {
        finished_region_only => {
            is => 'Boolean',
            default => 0,
            doc => 'If project is submitted, retrieve only the finished portion vs the entire contig sequence.',
        },
    },
    has_output => {
        output_file => {
            is => 'Text',
            is_optional => 1,
            doc => 'File name to putput consensus sequence. Defaults to "$PROJECTNAME.con" in current directory.'
        },
    },
    doc => 'get project consensus sequence',
};

sub help_detail { __PACKAGE__->__meta__->doc }

sub execute {
    my $self = shift;
    $self->status_message('Makecon...');

    $self->status_message('Project:  %s', $self->project->name);
    $self->status_message('Status: %s', $self->project->status);
    my $get_seq = $self->_get_seq;

    $self->output_file( join('.', $self->project->name, 'con') ) if not $self->output_file;
    $self->status_message('Output file: %s', $self->output_file);
    $get_seq->get_file($self->output_file);
    $self->fatal_message('Failed to write file!') unless -s $self->output_file;

    $self->status_message('Makecon...done');
    return 1;
}

sub _get_seq {
    my $self = shift;

    my %params = (
        type   => 'project',
        name   => $self->project->name,
        prefix => 1,
    );

    $self->status_message("Try to get consensus from latest submission...");
    my $get_seq;
    try {
        my %p = %params;
        $p{finished} = 1;
        $p{whole} = 1 if not $self->finished_region_only;
        $get_seq = GetSeq->new(%p);
    }
    catch {
        my $e = $_;
        $self->status_message("ERROR: $e");
    };
    return $get_seq if $get_seq;

    $self->status_message("Try to get consensus from latest ace file...");
    try {
        $get_seq = GetSeq->new(%params);
    }
    catch {
        $self->status_message("ERROR: $_");
    };
    return $get_seq if $get_seq;

    $self->fatal_message('Failed to get consenesus sequence!');
}

1;

