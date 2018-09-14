#!/usr/bin/env perl

use strict;
use warnings;

use TenxTestEnv;
use Test::More tests => 1;

Tenx::Config::set('tenx_ds_server', 'server');
Tenx::Config::set('tenx_ds_owner', 'owner');
Tenx::Config::set('tenx_ds_login', 'login');
Tenx::Config::set('tenx_ds_auth', 'auth');
Tenx::Config::set('tenx_ds_database', 'database');

use_ok('Tenx::DataSource::MySQL');

done_testing();
