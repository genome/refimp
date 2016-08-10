package RefImp;

use warnings;
use strict;

our $VERSION = '0.010100';

use Carp;
use Carp::Heavy;
require Sys::Hostname;

require Genome::Config;
require RefImp::Config;
use UR;

UR::Object::Type->define(
    class_name => 'RefImp',
    is => ['UR::Namespace'],
    english_name => 'reference improvement',
);

if ( Genome::Config::get('dev_mode') || UR::DBI->no_commit ) {
    my $h = Sys::Hostname::hostname;
    warn "***** DEV MODE ($h) *****";
}

# Account for a perl bug in pre-5.10 by applying a runtime patch to Carp::Heavy
if ($] < 5.01) {
    no warnings;
    *Carp::caller_info = sub {
        package
            Carp;
        our $MaxArgNums;
        my $i = shift(@_) + 1;
        package DB;
        my %call_info;
        @call_info{
            qw(pack file line sub has_args wantarray evaltext is_require)
        } = caller($i);

        unless (defined $call_info{pack}) {
            return ();
        }

        my $sub_name = Carp::get_subname(\%call_info);
        if ($call_info{has_args}) {
            # SEE IF WE CAN GET AROUND THE BIZARRE ARRAY COPY ERROR...
            my @args = ();
            if ($MaxArgNums and @args > $MaxArgNums) { # More than we want to show?
                $#args = $MaxArgNums;
                push @args, '...';
            }
            # Push the args onto the subroutine
            $sub_name .= '(' . join (', ', @args) . ')';
        }
        $call_info{sub_name} = $sub_name;
        return wantarray() ? %call_info : \%call_info;
    };
    use warnings;
}

1;

