#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;
use Test::More tests => 1;

Refimp::Config::set('ds_mysql_server', 'server');
Refimp::Config::set('ds_mysql_owner', 'owner');
Refimp::Config::set('ds_mysql_login', 'login');
Refimp::Config::set('ds_mysql_auth', 'auth');
Refimp::Config::set('ds_mysql_database', 'database');

use_ok('Refimp::DataSource::MySQL');

done_testing();
