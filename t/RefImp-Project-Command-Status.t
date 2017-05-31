#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::Command::Status';
use_ok($pkg) or die;

subtest 'execute' => sub {
    plan tests => 2;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    ok($pkg->execute(projects => [ RefImp::Project->get(1) ]), 'execute');
    like($output, qr/ID\s+NAME\s+STATUS\s+ACCESSIONS\s+[-\s]+/, 'output matches');

};

done_testing();
