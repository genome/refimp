#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

use_ok('RefImp::Project::Command::Submission::List') or die;
done_testing();
