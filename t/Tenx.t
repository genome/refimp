#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;
use Test::More tests => 1;

subtest 'tenx' => sub{
    plan tests => 1;

    use_ok('Tenx') or die;

};

done_testing();
