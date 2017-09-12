#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;
use Test::Exception;
use Test::More tests => 3;

my $pkg = 'RefImp::Project::Digest';
use_ok($pkg) or die;

subtest 'resolve_project_basename' => sub {
    plan tests => 5;

    throws_ok(sub{ $pkg->resolve_project_basename; }, qr/but 2 were expected/, 'project_basename fails w/o name');

    my %names_and_expected_basenames = (
        'C_AD-1003B23' => '1003B23',
        'H_NH0001A01' => '0001A01',
        'JE001F11' => '001F11',
        'VMRC59-256H11' => 'C59-256H11',
    );
    for my $name ( sort keys %names_and_expected_basenames ) {
        is($pkg->resolve_project_basename($name), $names_and_expected_basenames{$name}, "$name basename is $names_and_expected_basenames{$name}");
    }

};

subtest 'new' => sub{
    plan tests => 10,

    throws_ok(sub{ $pkg->new; }, qr/ERROR No project name/, "new fails w/o project");

    my $digest = $pkg->new('VMRC59-256H11');
    ok($digest, 'create digest');
    is($digest->project_name, 'VMRC59-256H11', 'set project_name');
    is($digest->project_basename, 'C59-256H11', 'set project_basename');

    my %info = (
        project_header => '0001A01a',
        bands => [1, -1],
        date => '160101',
    );
    ok(!$digest->add_digest_info(%info), 'did not add digest info');

    $info{project_header} = 'C59-256H11e';
    ok($digest->add_digest_info(%info), 'add digest info');
    is($digest->bands, $info{bands}, 'added digest bands');
    is($digest->date, $info{date}, 'added digest date');
    is($digest->enzyme, 'EcoRV', 'set enzyme');

    throws_ok(sub{ $digest->add_digest_info(%info); }, qr/ERROR Cannot add digest info twice/, 'failed to add digest info again');

};

done_testing();
