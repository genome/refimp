#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

use_ok('RefImp::Cron::Command') or die;
done_testing();
