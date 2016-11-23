#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Spec qw();
use Test::More tests => 2;

my $clone;
subtest "basics" => sub{
    plan tests => 6;

    use_ok('RefImp::Clone') or die;

    $clone = RefImp::Clone->get(1);
    ok($clone, 'got clone');
    ok($clone->name, 'clone has a name');
    ok($clone->__display_name__, '__display_name__');
    ok($clone->type, 'clone has a type');
    ok($clone->status, 'clone has a status');

};

subtest 'project' => sub{
    plan tests => 2;

    my $project = RefImp::Project->get(1);
    ok($project, 'got project');
    is($clone->project, $project, 'got project via clone');

};

done_testing();
