#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

RefImp::Config::set('ds_mysql_server', 'server');
RefImp::Config::set('ds_mysql_owner', 'owner');
RefImp::Config::set('ds_mysql_login', 'login');
RefImp::Config::set('ds_mysql_auth', 'auth');
RefImp::Config::set('ds_mysql_database', 'database');

use_ok('RefImp::DataSource::MySQL');

done_testing();
