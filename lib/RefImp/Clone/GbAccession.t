#!/usr/bin/env lims-perl

use strict;
use warnings;

use above 'RefImp';

use RefImp::Test;
use Test::More tests => 2;

my $pkg = 'RefImp::Clone::GbAccession';
use_ok($pkg) or die;

subtest 'basics' => sub {
    plan tests => 5;

    my $gb_accession = $pkg->create(
        acc_number => 'AC1111',
        center => 'WUGSC',
        project_id => 1,
        version => 1,
        rank => 1,
    );
    ok($gb_accession->acc_number, 'acc_number');
    ok($gb_accession->center, 'center');
    ok($gb_accession->project_id, 'project_id');
    ok($gb_accession->rank, 'rank');
    ok($gb_accession->version, 'version');

};

done_testing();
