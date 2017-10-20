#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;
use Test::More tests => 1;

use_ok('RefImp::Taxon::Command') or die;
done_testing();
