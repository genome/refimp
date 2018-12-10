#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::Exception;
use Test::More tests => 1;

subtest 'execute' => sub {
    plan tests => 3;

    my $pkg = 'RefImp::Assembly::Command::Submission::NcbiBiosample';
    use_ok($pkg) or die;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $pkg->execute; }, 'execute');
    like($output, qr/Submission Info Field Docs\n/, 'info printed');

};

done_testing();
