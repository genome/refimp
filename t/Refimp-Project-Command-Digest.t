#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

use_ok('Refimp::Project::Command::Digest') or die;
done_testing();
