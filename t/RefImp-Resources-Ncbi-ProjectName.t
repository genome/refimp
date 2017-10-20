#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use Test::More tests => 3;

my $pkg = 'RefImp::Resources::Ncbi::ProjectName';
use_ok($pkg) or die;

my %local_and_ncbi_names = (
    'VMRC59-256H11' => 'VMRC59-256H11',
    'H_GD-274A02' => 'CH17-274A2',
    'H_DJ-300A01' => 'RP1-300A1',
    'H_DJ-500A01' => 'RP3-500A1',
    'H_DJ-600A01' => 'RP4-600A1',
    'H_DJ-900A01' => 'RP5-900A1',
    'H_DJ-1300A01' => 'H_DJ-1300A01',
);

subtest 'get' => sub{
    plan tests => scalar keys %local_and_ncbi_names;

    for my $local ( sort keys %local_and_ncbi_names ) {
        is($pkg->get($local), $local_and_ncbi_names{$local}, "local_to_ncbi $local => $local_and_ncbi_names{$local}");
    }

};

subtest 'ncbi_to_local' => sub{
    plan tests => scalar keys %local_and_ncbi_names;

    for my $local ( sort keys %local_and_ncbi_names ) {
        is($pkg->ncbi_to_local($local_and_ncbi_names{$local}), $local, "ncbi_to_local $local_and_ncbi_names{$local} => $local");
    }

};

done_testing();
