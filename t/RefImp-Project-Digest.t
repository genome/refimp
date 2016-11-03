#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::Exception;
use Test::More tests => 3;

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

subtest 'new' => sub{
    plan tests => 5,

    my %digest = (
        bands => [1],
        band_cnt => 1,
        project_header => '0001A01aa',
        date => '160101',
    );
    for my $attr ( keys %digest ) {
        my $v = delete $digest{$attr};
        throws_ok(sub{ RefImp::Project::Digest->new(%digest); }, qr/ERROR No $attr/, "new fails w/o $attr");
        $digest{$attr} = $v
    }

    my $digest = RefImp::Project::Digest->new(%digest);
    ok($digest, 'create digest');
};

done_testing();
