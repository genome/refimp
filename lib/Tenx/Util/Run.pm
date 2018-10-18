package Tenx::Util::Run;

use strict;
use warnings 'FATAL';

use File::stat 'stat';
use Path::Class;
use Tenx::Util::Run::Log;

sub location { $_[0]->{location} }

sub new {
    my ($class, $location) = @_;
    die "No run location given!" if not $location;
    die "Run location needs to be a Path::Class::Dir! $location" if not $location->isa('Path::Class::Dir');
    die "Run location given does not exist!" if not -d "$location";
    bless { location => $location }, $class;
}

sub status {
    my ($self) = @_;

}

sub log_file {
    $_[0]->location->file('_log');
}

sub log {
    Tenx::Util::Run::Log->create(log_file => $_[0]->log_file);
}

sub journal_status {
    my ($self) = @_;

    my $journal_path = $self->location->subdir('journal');
    return 'unknown' if not -d "$journal_path";

    my $journal_st = stat($journal_path);
    return 'unknown' if not $journal_st;

    my $journal_access_diff = ((time() - $journal_st->mtime) / 60);
    return 'zombie' if $journal_access_diff > 10;
    'running';
}

sub outs_directory {
    $_[0]->location->subdir('outs');
}

sub summary_csv {
    $_[0]->outs_directory->file('summary.csv');
}

1;
