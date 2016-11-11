package RefImp::Config::CLI;

use strict;
use warnings;

use List::MoreUtils 'any';
use RefImp::Config;

sub run {
    my $class = shift;

    my %functions_and_usages = (
        get => "[USAGE] refimp-config get \$KEY",
        ds  => "[USAGE] refimp-config ds \$DATASOURCE",
    );
    $functions_and_usages{help} = join("\n", values %functions_and_usages);
    die "[ERROR] No function given!\n$functions_and_usages{help}" if ! @_;
    my $function = shift;
    die "[ERROR] Unknown function: $function" if not any { $function eq $_ } keys %functions_and_usages;
    print "$functions_and_usages{help}\n" and return 0 if $function eq 'help';

    RefImp::Config::load_refimp_config_file() if ! RefImp::Config::is_loaded();
    if ( $function eq 'get' ) {
        my $key = shift;
        die "[ERROR] Missing key to get config!\n$functions_and_usages{get}\n" if ! defined $key;
        print RefImp::Config::get($key);
    }
    elsif ( $function eq 'ds' ) {
        my $ds = shift;
        die "[ERROR] Missing datasource to get config!\n$functions_and_usages{get}\n" if ! defined $ds;
        my $server = RefImp::Config::get('ds_'.$ds.'_server');
        my $login = eval{ RefImp::Config::get('ds_'.$ds.'_login') };
        my $auth = eval{ RefImp::Config::get('ds_'.$ds.'_auth') };
        if ( not $login and not $auth ) {
            print "$server\n";
        }
        else { 
            printf("%s/%s@%s\n", $login, $auth, $server);
        }
    }

    return 0;
}

1;

