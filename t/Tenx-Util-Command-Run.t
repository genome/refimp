#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;
use Test::More tests => 1;

use_ok('Tenx::Util::Command::Run') or die;
done_testing();
