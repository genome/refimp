#!/usr/bin/env lims-perl

use strict;
use warnings;

use above 'RefImp';
use Test::More tests => 1;

use_ok('RefImp::Project::Command::Update') or die;
done_testing();