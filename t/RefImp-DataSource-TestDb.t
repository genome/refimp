#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use lib '.';


use TestEnv;
use Test::More tests => 1;

RefImp::Config::set('ds_oltp_server', 'server');
use_ok('RefImp::DataSource::TestDb');

done_testing();
