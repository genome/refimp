#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

Refimp::Config::set('ds_oltp_server', 'server');
use_ok('Refimp::DataSource::TestDb');

done_testing();
