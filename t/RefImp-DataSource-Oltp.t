#!/usr/bin/env perl5.12.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

RefImp::Config::set('ds_oltp_server', 'server');
RefImp::Config::set('ds_oltp_login', 'login');
RefImp::Config::set('ds_oltp_auth', 'auth');
RefImp::Config::set('ds_oltp_owner', 'owner');
use_ok('RefImp::DataSource::Oltp');

done_testing();
