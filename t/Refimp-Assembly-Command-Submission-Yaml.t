#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 1;

subtest 'print YAML' => sub {
    plan tests => 3;

    my $pkg = 'Refimp::Assembly::Command::Submission::Yaml';
    use_ok($pkg) or die;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $pkg->execute; }, 'print submission yaml');
    like($output, qr/---\n/, 'yaml printed');

};

done_testing();
