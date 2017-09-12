#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

Refimp::Config::set('ds_oltp_server', 'server');
Refimp::Config::set('ds_oltp_login', 'login');
Refimp::Config::set('ds_oltp_auth', 'auth');
Refimp::Config::set('ds_oltp_owner', 'owner');
use_ok('Refimp::DataSource::Oltp');

done_testing();
