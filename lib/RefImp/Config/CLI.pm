package RefImp::Config::CLI;

use strict;
use warnings;

use List::MoreUtils 'any';
use RefImp::Config;

sub run {
    my $class = shift;

    my %functions_and_usages = (
        get => "[USAGE] refimp-config get \$KEY",
    );
    $functions_and_usages{help} = join("\n", values %functions_and_usages);
    die "[ERROR] No function given!\n$functions_and_usages{help}" if ! @_;
    my ($function, $key) = @_;
    die "[ERROR] Unknown function: $function" if not any { $function eq $_ } keys %functions_and_usages;
    print "$functions_and_usages{help}\n" and return 0 if $function eq 'help';

    RefImp::Config::load_refimp_config_file() if ! RefImp::Config::is_loaded();
    if ( $function eq 'get' ) {
        die "[ERROR] Missing key to get config!\n$functions_and_usages{get}\n" if ! defined $key;
        print RefImp::Config::get($key);
    }

    return 0;
}

1;

