#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;
use Test::More tests => 1;

use_ok('Tenx::Command::Reads::List') or die;
done_testing();
