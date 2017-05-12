#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my $pkg = 'RefImp::Assembly::Command::Submission::Yaml';
use_ok($pkg) or die;

subtest 'print YAML' => sub {
    plan tests => 2;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $pkg->execute; }, 'print submission yaml');
    like($output, qr/---\n/, 'yaml printed');

};

subtest 'info hash' => sub{
    plan tests => 2;

    my %info = $pkg->submission_info_hash;
    ok(%info, 'submission_info_hash');
    my @keys = sort keys %info;
    is_deeply(\@keys, [$pkg->submission_info_keys], 'submission_info_keys');

};

done_testing();
