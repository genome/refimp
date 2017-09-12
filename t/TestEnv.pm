package TestEnv;

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;
use Sys::Hostname;
use Test::MockObject;

my $current_repo_path;
INIT { # runs after compilation, right before execution
    $current_repo_path = resolve_repo_path( (caller())[1] );
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_DBI_NO_COMMIT} = 1;

    my $lib = File::Spec->join($current_repo_path, 'lib');
    eval "use lib '$lib';";
    die "FATAL: $@" if $@;

    my $use = <<USE;
    use Refimp;
USE
    eval $use;
    die "FATAL: $@" if $@;

    my $test_data_path = File::Spec->join($current_repo_path, 't', 'data');

    Refimp::Config::set('analysis_directory', File::Spec->join($test_data_path, 'analysis'));
    Refimp::Config::set('environment', 'test');
    Refimp::Config::set('ds_mysql', 'Refimp::DataSource::TestDb');
    Refimp::Config::set('ds_oltp', 'Refimp::DataSource::TestDb');
    Refimp::Config::set('ds_testdb_server', File::Spec->join($test_data_path, 'test.db'));
    Refimp::Config::set('net_ldap_url', 'ipa.refimp.org');
    Refimp::Config::set('seqmgr', File::Spec->join($test_data_path, 'seqmgr'));
    Refimp::Config::set('test_data_path', $test_data_path);

    printf(STDERR "***** TEST ENV on %s *****\n", Sys::Hostname::hostname);
}

sub current_repo_path { $current_repo_path };

sub resolve_repo_path {
    my $file = shift;
    die "No file given to resolve lib path!" if not $file;
    die "File given to resolve lib path does not exist!" if not -e $file;
    my @directory_parts = File::Spec->splitdir( File::Spec->rel2abs( dirname($file) ) );
    pop @directory_parts;
    File::Spec->join(@directory_parts);
}

sub test_data_directory_for_package {
    my $pkg = shift;
    die 'No package given to get test data directory' if not $pkg;
    File::Spec->join( Refimp::Config::get('test_data_path'), join('-', map { s/Refimp/Refimp/; $_ } split('::', $pkg)) );
}

package TestEnv::LimsRestApi;

use strict;
use warnings 'FATAL';

use Sub::Install;

sub setup {
    my %info = ( @_ ) # pass in if ya wanna
    ? @_
    : (
        species_name => 'human',
        chromosome => 7,
        species_latin_name => 'Homo sapiens',
    );

    my $lims_rest_api = Test::MockObject->new;
    $lims_rest_api->mock(
        'query',
        sub{
            my ($self, $object, $method) = @_;
            return $info{$method};
        },
    );

    eval('use Refimp::Resources::LimsRestApi;');
    Sub::Install::reinstall_sub({
            code => sub{ $lims_rest_api },
            into => 'Refimp::Resources::LimsRestApi',
            as => 'new'
        });
}

package TestEnv::NcbiFtp;

use strict;
use warnings 'FATAL';

use Net::FTP;
use Sub::Install;
use Test::MockObject;

my $ftp;
sub setup {
    my $class = shift;

    return $ftp if $ftp;

    Refimp::Config::set('ncbi_ftp_host', 'ftp-host');
    Refimp::Config::set('ncbi_ftp_user', 'ftp-user');
    Refimp::Config::set('ncbi_ftp_password', 'ftp-password');

    my $ftp = Test::MockObject->new;
    $ftp->set_true('login');
    $ftp->set_true('cwd');
    $ftp->set_true('binary');
    $ftp->set_true('quot');
    $ftp->set_true('put');
    Sub::Install::reinstall_sub({
            code => sub { $ftp },
            as => 'new',
            into => 'Net::FTP',
        });

    return $ftp;
}

1;
