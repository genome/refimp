#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;
use Test::More tests => 1;

use_ok('Tenx::DataSource::SQLite');

done_testing();
