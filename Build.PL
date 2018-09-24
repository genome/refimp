#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Module::Build;

my $build = Module::Build->new(
    module_name => 'RefImp',
    license => 'perl',
    dist_author => 'Eddie Belter <ebelter@cpan.org>',
    dist_abstract => 'Reference Improvement Command',
    dist_version => '0.01',
    build_requires => {
        'Module::Build' => 0,
    },
    sqlite3 => { 'lib/RefImp/DataSource/Meta.sqlite3' => 'lib/RefImp/DataSource/Meta.sqlite3', },
    'sqlite3-dump' => { 'lib/RefImp/DataSource/Meta.sqlite3-dump' => 'lib/RefImp/DataSource/Meta.sqlite3-dump', },
);
$build->add_build_element('sqlite3');
$build->add_build_element('sqlite3-dump');
$build->add_build_element('xsd');
$build->create_build_script;
