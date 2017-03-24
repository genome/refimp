#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

RefImp::Config::set('ds_oltp_server', 'server');
use_ok('RefImp::DataSource::TestDb');

done_testing();
