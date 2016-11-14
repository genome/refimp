#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 2;

my $pkg = 'RefImp::Resources::Ncbi::ProjectName';
use_ok($pkg) or die;

subtest 'get' => sub{
    plan tests => 7;

    is($pkg->get('VMRC59-256H11'), 'VMRC59-256H11', 'ncbi_name_for_clone_name VMRC59-256H11');
    is($pkg->get('H_GD-274A02'), 'CH17-274A2', 'ncbi_name_for_clone_name H_GD-274A02');
    is($pkg->get('H_DJ-300A01'), 'RP1-300A1', 'ncbi_name_for_clone_name H_DJ300A01');
    is($pkg->get('H_DJ-500A01'), 'RP3-500A1', 'ncbi_name_for_clone_name H_DJ500A01');
    is($pkg->get('H_DJ-600A01'), 'RP4-600A1', 'ncbi_name_for_clone_name H_DJ600A01');
    is($pkg->get('H_DJ-900A01'), 'RP5-900A1', 'ncbi_name_for_clone_name H_DJ800A01');
    is($pkg->get('H_DJ-1300A01'), 'H_DJ-1300A01', 'ncbi_name_for_clone_name H_DJ1300A01');

};

done_testing();
