#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Test::Exception;
use Test::More tests => 3;

#our $system_mock = sub{ die "No system sub set" };
#use Test::Mock::Cmd 'system' => sub{ $system_mock->(@_) };

use IPC::Cmd;
use Sub::Install;
our %test = (
    class => 'Util::GCP',
    success => 1,
);
subtest 'setup' => sub{
    plan tests => 1;

    use_ok($test{class}) or die;

    $test{mock_cmd} = sub{ die "No mock command set" };
    Sub::Install::reinstall_sub({
            code => sub{ $test{mock_cmd}->(@_); },
            as => 'run',
            into => 'IPC::Cmd',
        });

    $test{rsync_mock_cmd} = sub{
        is_deeply(\@_, ['command', [qw/ gsutil rsync -r src dest/], 'verbose', 0], 'correct command');
        ( $test{success}, 'ERROR' );
    };

my $out = <<OUT;
                           gs://mgi-rg-linked-reads-ccdg-pilot/assembly/
                           gs://mgi-rg-linked-reads-ccdg-pilot/reads/
                           gs://mgi-rg-linked-reads-ccdg-pilot/software/
 852601404  2018-04-23T20:50:52Z  gs://mgi-rg-linked-reads-ccdg-pilot/supernova-2.0.1.tar.gz
      2005  2018-06-26T18:15:58Z  gs://mgi-rg-linked-reads-ccdg-pilot/verify-upload.pl
TOTAL: 2 objects, 852603409 bytes (813.11 MiB)
OUT
	my @out = split(/\n/, $out);
	$test{ls_expected_result} = [
		{
			'type' => 'd',
			'name' => 'gs://mgi-rg-linked-reads-ccdg-pilot/assembly/'
		},
		{
			'type' => 'd',
			'name' => 'gs://mgi-rg-linked-reads-ccdg-pilot/reads/'
		},
		{
			'name' => 'gs://mgi-rg-linked-reads-ccdg-pilot/software/',
			'type' => 'd'
		},
		{
			'type' => 'f',
			'size' => '852601404',
			'name' => 'gs://mgi-rg-linked-reads-ccdg-pilot/supernova-2.0.1.tar.gz',
			'date' => '2018-04-23T20:50:52Z'
		},
		{
			'size' => '2005',
			'date' => '2018-06-26T18:15:58Z',
			'name' => 'gs://mgi-rg-linked-reads-ccdg-pilot/verify-upload.pl',
			'type' => 'f'
		}
	];
	$test{ls_mock_cmd} = sub{
		is_deeply(\@_, ['command', [qw# gsutil ls -l gs://mgi-rg-linked-reads-ccdg-pilot/ #], 'verbose', 0], 'correct command');
		( $test{success}, '', \@out, \@out );
	};

};

subtest 'rsync' => sub {
    plan tests => 6;

    my $err;
    open local(*STDERR), '>', \$err or die $!;
    local $test{mock_cmd} = $test{rsync_mock_cmd};

    throws_ok(sub{ $test{class}->rsync(); }, qr/No source given to rsync/, 'fails w/o source');
    throws_ok(sub{ $test{class}->rsync('src'); }, qr/No destination given to rsync/, 'fails w/o destination');

    lives_ok(sub{ $test{class}->rsync('src', 'dest'); }, 'success');

    local $test{success} = 0;
    throws_ok( sub{ $test{class}->rsync('src', 'dest'); }, qr/Failed to run gsutil/, 'handles run failure');

};


subtest 'ls' => sub {
    plan tests => 6;

    my ($err, $result);
    my $src = 'gs://mgi-rg-linked-reads-ccdg-pilot/';
    open local(*STDERR), '>', \$err or die $!;
    local $test{mock_cmd} = $test{ls_mock_cmd};

    throws_ok(sub{ $test{class}->ls(); }, qr/No source given to ls/, 'fails w/o source');

    lives_ok( sub{ $result = $test{class}->ls($src); }, 'success');
    is_deeply($result, $test{ls_expected_result}, 'got ls result');

    local $test{success} = 0;
    throws_ok( sub{ $test{class}->ls($src); }, qr/Failed to run gsutil/, 'handles run failure');

};

done_testing();
