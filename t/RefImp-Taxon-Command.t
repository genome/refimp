#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

use_ok('RefImp::Taxon::Command') or die;
done_testing();