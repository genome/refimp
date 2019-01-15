package Pacbio::Run::Duration;

use strict;
use warnings 'FATAL';

use File::Find 'find';
use IO::File;
use Path::Class;

sub directory { $_{0}->{directory} }

sub new {
    my ($class) = @_;

    die "No directory given!" if not $_[1];
    my $directory = dir($ARGV[0])->absolute;
    die "Directory does not exists! $directory" if not -d "$directory";

    bless { directory => $directory }, $class;
}

sub find_stages_and_durations {
	my ($self) = @_;

    my %stages;
    my $total = 0;
	find(
		{
			wanted => sub{
				if ( /stderr$/) {
                    my ($stage, $duration) = get_stage_and_duration($File::Find::name);
                    return if not $done_file;
                    $total += $duration;
                    for my $i ( 0 .. $#stage ) {
                        my $name = join(' ', @stage[0..$i]);
                        $stages{$name} += $duration;
                    }
				}
			},
		},
		glob($self->directory->file('*')->stringify),
	);

    $stages{total} = $total;
    print join("\n", map { join(' ', $_, $stages{$_}) } sort keys %stages)."\n";

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
    pop @components if $components[$#components] =~ /_\d{3,}$/; # remove the chunked steps
    die "Cannot derive stage from done file: $file" if not @components;
    \@components;
}

1;
