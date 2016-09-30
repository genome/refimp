package RefImp::Project::NotesFile;

use strict;
use warnings;

use Params::Validate ':types';
use Tie::File;

sub new {
    my ( $class, $file_name) = Params::Validate::validate_pos(@_, {isa => __PACKAGE__}, {type => SCALAR});
    die "File does not exist! $file_name" if not -s $file_name;
    tie my @file, 'Tie::File', $file_name or die "Failed to tie file! $file_name";
    return bless { file_name => $file_name, file => \@file }, $class;
}

sub prefinishers { _user_name_for_key($_[0], 'SORTER') }
sub finishers { _user_name_for_key($_[0], 'FINISHER') }
sub _user_name_for_key {
    my($self, $key) = @_;

    my $value = List::MoreUtils::firstval { m/$key/ } @{$self->{file}} ;
    return 'NA' if not $value;
    chomp $value;
    $value =~ s/^\s*$key\=\s*//;
    return List::MoreUtils::uniq( split(/,\s+|\//, $value) );
}

1;

