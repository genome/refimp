#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;
use Test::More tests => 1;

RefImp::Config::set('refimp_ds_oltp_server', 'server');
RefImp::Config::set('refimp_ds_oltp_login', 'login');
RefImp::Config::set('refimp_ds_oltp_auth', 'auth');
RefImp::Config::set('refimp_ds_oltp_owner', 'owner');
use_ok('RefImp::DataSource::Oltp');

done_testing();
