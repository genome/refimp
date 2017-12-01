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

    my $bin = File::Spec->join($current_repo_path, 'bin');
    $ENV{PATH} = "$bin:$ENV{PATH}";

    my $lib = File::Spec->join($current_repo_path, 'lib');
    eval "use lib '$lib';";
    die "FATAL: $@" if $@;

    my $use = <<USE;
    use RefImp;
USE
    eval $use;
    die "FATAL: $@" if $@;

    my $test_data_path = File::Spec->join($current_repo_path, 't', 'data');

    RefImp::Config::set('analysis_directory', File::Spec->join($test_data_path, 'analysis'));
    RefImp::Config::set('environment', 'test');
    RefImp::Config::set('refimp_ds', 'RefImp::DataSource::TestDb');
    RefImp::Config::set('refimp_ds_oltp', 'RefImp::DataSource::TestDb');
    RefImp::Config::set('ds_testdb_server', File::Spec->join($test_data_path, 'test.db'));
    RefImp::Config::set('net_ldap_url', 'ipa.refimp.org');
    RefImp::Config::set('test_data_path', $test_data_path);

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
    File::Spec->join( RefImp::Config::get('test_data_path'), join('-', split('::', $pkg)) );
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

    eval('use RefImp::Resources::LimsRestApi;');
    Sub::Install::reinstall_sub({
            code => sub{ $lims_rest_api },
            into => 'RefImp::Resources::LimsRestApi',
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

    RefImp::Config::set('ncbi_ftp_host', 'ftp-host');
    RefImp::Config::set('ncbi_ftp_user', 'ftp-user');
    RefImp::Config::set('ncbi_ftp_password', 'ftp-password');

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

package TestEnv::NcbiBiosample;

use strict;
use warnings 'FATAL';

use File::Slurp 'slurp';
use List::MoreUtils;
use LWP::UserAgent;
use Path::Class qw/ dir file/ ;
use Sub::Install;
use Test::MockObject;

sub setup {

	my $ua = Test::MockObject->new();
	$ua->set_true('timeout');
	$ua->set_true('env_proxy');

	Sub::Install::reinstall_sub({
			code => sub{ $ua },
			into => 'LWP::UserAgent',
			as => 'new',
		});

	my %responses;
    my @request_types = (qw/ elink esummary /);
    my $data_dir = dir( TestEnv::test_data_directory_for_package('RefImp::Resources::Ncbi::Biosample') );
	for my $request_type ( @request_types ) {
		my $xml_file = $data_dir->file($request_type.'.xml');
        die "XML $request_type file does not exist! $xml_file" if not -s "$xml_file";
		my $xml_content = slurp($xml_file);
        die "Failed to load $request_type XML file!" if not $xml_content;

		my $response = Test::MockObject->new();
        $response->set_true('is_success');
		$response->set_always('decoded_content', $xml_content);
        $responses{$request_type} = $response;
	}

	$ua->mock(
        'get',
		sub{
			my ($ua, $url) = @_;
            my $requested_type = List::MoreUtils::firstval { $url =~ /$_/ } @request_types;
            return $responses{$requested_type};
		},
	);

	return $ua;
}

1;
