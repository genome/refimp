#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

use_ok('Refimp::Taxon::Command::List') or die;
done_testing();
