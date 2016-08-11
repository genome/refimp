#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use File::Slurp 'slurp';
use File::Spec;
use Test::More tests => 2;
use YAML;

my $pkg = 'RefImp::Clone::Submissions::Form';
use_ok($pkg) or die;

subtest 'create' => sub{
    plan tests => 1;

    my $hash = YAML::LoadFile( File::Spec->join(RefImp::Test->test_data_directory_for_package($pkg), 'expected.yml') );
    my $expected_form = slurp( File::Spec->join(RefImp::Test->test_data_directory_for_package($pkg), 'expected.form') );
    my $form = $pkg->create($hash);
    is($form, $expected_form, 'submissions form');

};

done_testing();
