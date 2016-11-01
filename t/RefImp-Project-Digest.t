#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::Exception;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::Digest';
use_ok($pkg) or die;

subtest 'project_basename' => sub {
    plan tests => 5;

    throws_ok(sub{ $pkg->project_basename; }, qr/but 2 were expected/, 'project_basename fails w/o name');

    my %names_and_expected_basenames = (
        'C_AD-1003B23' => '1003B23',
        'H_NH0001A01' => '0001A01',
        'JE001F11' => '001F11',
        'VMRC59-256H11' => 'C59-256H11',
    );
    for my $name ( sort keys %names_and_expected_basenames ) {
        is($pkg->project_basename($name), $names_and_expected_basenames{$name}, "$name basename is $names_and_expected_basenames{$name}");
    }

};

done_testing();
