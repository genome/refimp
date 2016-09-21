#!/usr/bin/env perl5.12.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

my $pkg = 'RefImp::User::WorkFunction';
subtest "basics" => sub{
    plan tests => 4;

    use_ok($pkg) or die;

    my $wf = $pkg->create(name => 'finishing', status => 'active');
    ok($wf, 'create user work function');
    ok($wf->name, 'name');
    ok($wf->status, 'status');

};

done_testing();
