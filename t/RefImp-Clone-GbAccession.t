#!/usr/bin/env perl5.12.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 1;

my $pkg = 'RefImp::Clone::GbAccession';

subtest 'basics' => sub {
    plan tests => 6;

    use_ok($pkg) or die;

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
