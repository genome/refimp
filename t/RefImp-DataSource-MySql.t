#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;
use Test::More tests => 1;

RefImp::Config::set('refimp_ds_server', 'server');
RefImp::Config::set('refimp_ds_owner', 'owner');
RefImp::Config::set('refimp_ds_login', 'login');
RefImp::Config::set('refimp_ds_auth', 'auth');
RefImp::Config::set('refimp_ds_database', 'database');

use_ok('RefImp::DataSource::MySQL');

done_testing();
