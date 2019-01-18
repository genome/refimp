package Pacbio::Assembly::Run;

use strict;
use warnings 'FATAL';

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/ directory stages /);

use File::Find 'find';
use IO::File;
use Path::Class;

sub new {
    my ($class) = @_;

    die "No directory given!" if not $_[1];
    my $directory = dir("$_[1]")->absolute;
    die "Directory does not exists! $directory" if not -d "$directory";

    bless { directory => $directory }, $class;
}

sub get_stages {
	my ($self) = @_;

    my %stages;
	find(
		{
			wanted => sub{
				if ( /stderr$/) {
                    my ($stage, $duration) = get_stage_and_duration($File::Find::name);
                    return if not $stage;
                    $stages{ $stage->[0] }->{duration} += $duration;
                    if ( @$stage > 1 ) {
                        my $end = @$stage - 1;
                        my $name = join(' ', @$stage[1..$end]);
                        $stages{ $stage->[0] }->{substages}->{$name} += $duration;
                    }
				}
			},
		},
		glob($self->directory->file('*')->stringify),
	);

    $self->stages(\%stages);

}

sub get_stage_and_duration {
	my ($file) = @_;

    my $fh = IO::File->new("$file");
    die "Failed to open file: $file" if not $fh;

    my ($done_file);
    my $duration = 0;
    while ( my $l = $fh->getline ) {
        if ( $l =~ /^real\s(.+)/ ) {
            $duration += get_duration_from_time_output("$1");
        }
        elsif ( $l =~ /^touch\s+(.+)/ ) {
            $done_file = $1;
        }
    }
    $fh->close;

    ( get_stage_from_file_name($done_file), $duration );
}

sub get_duration_from_time_output {
    my ($time_output) = @_;

    my $duration = 0;
    my ($min, $sec) = split('m', $time_output);
    $duration += $min * 60 if $sec;
    $sec =~ s/s$//;
    $duration += $sec;
    $duration;
}

sub get_stage_from_file_name {
    my ($file) = @_;

    my @components = file($file)->components;
    shift @components if $components[0] eq ''; # remove the root
    do {
        shift @components;
    } until $components[0] =~ /^\d\-/;
    pop @components if $components[$#components] eq 'run.sh.done'; # remove run.sh.done

    # Remove the chunked steps: j_0000 000000F chunk_000000F segr000
    pop @components if $components[$#components] =~ /\d{3,}/;
    pop @components if $components[$#components] =~ /^segr\d+$/;

    die "Cannot derive stage from done file: $file" if not @components;
    \@components;
}

1;
