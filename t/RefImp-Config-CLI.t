#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 6;

my $pkg = 'RefImp::Config::CLI';
use_ok($pkg) or die;

subtest 'failures' => sub{
    plan tests => 2;

    throws_ok(sub{ $pkg->run; }, qr/\[ERROR\] No function given/, 'fails w/o ARGV');
    throws_ok(sub{ $pkg->run('blah'); }, qr/\[ERROR\] Unknown function: blah/, 'fails w/ invalid function ARGV');

};

subtest 'help' => sub{
    plan tests => 2;

    run_ok([qw/ help /], qr/^\[USAGE\] refimp-config get/); 
};

subtest 'get' => sub{
    plan tests => 3;

    throws_ok(sub{ $pkg->run('blah'); }, qr/\[ERROR\] Unknown function: blah/, 'fails w/ invalid function ARGV');
    run_ok([qw/ get environment /], qr/^test$/); 

};

subtest 'ds' => sub{
    plan tests => 2;

    run_ok([qw/ ds testdb /], qr/test.db$/); 

};

subtest 'list' => sub{
    plan tests => 2;

    run_ok([qw/ list /], qr/^\-\-\-\n/); 

};

done_testing();

###

sub run_ok {
    my ($params, $expected_output) = @_;
    my $output;
    open local( *STDOUT), '>', \$output or die $!;
    my $rv = $pkg->run(@$params);
    is($rv, 0, "RUN ".join(' ', @$params));
    like($output, $expected_output, "OUPUT ".join(' ', @$params));
}

