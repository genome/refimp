#!/usr/bin/env perl5.12.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

use_ok('RefImp::Clone::Command::List') or die;
done_testing();
