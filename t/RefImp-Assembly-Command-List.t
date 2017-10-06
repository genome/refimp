#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use lib '.';


use TestEnv;
use Test::More tests => 1;

use_ok('RefImp::Assembly::Command::List') or die;
done_testing();
