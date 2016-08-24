#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

use_ok('RefImp::Project::Command::QaBase') or die;
done_testing();
