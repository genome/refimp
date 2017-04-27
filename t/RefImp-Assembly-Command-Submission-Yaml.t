#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 2;

my $pkg = 'RefImp::Assembly::Command::SubmissionYaml';
use_ok($pkg) or die;

subtest 'print YAML' => sub {
    plan tests => 2;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $pkg->execute; }, 'print submission yaml');
    like($output, qr/---\n/, 'yaml printed');

};

done_testing();
