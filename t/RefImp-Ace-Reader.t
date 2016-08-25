#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use IO::File;
use File::Spec;
use Test::More tests => 1;

subtest 'setup' => sub{
    plan tests => 2;

    my $pkg = 'RefImp::Ace::Reader';
    use_ok($pkg) or die;
    
    my $acefile = File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'HMPB-AAD13A05.fasta.ace.0');
    my $reader = $pkg->new($acefile);
    ok($reader, 'create reader');

};

done_testing();
