#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;
use Test::More tests => 1;

use_ok('RefImp::Tenx::Command::Reads::List') or die;
done_testing();
