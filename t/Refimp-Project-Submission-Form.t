#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Slurp 'slurp';
use File::Spec;
use Test::More tests => 2;
use YAML;

my $pkg = 'Refimp::Project::Submission::Form';
use_ok($pkg) or die;

subtest 'create' => sub{
    plan tests => 1;

    my $test_data_dir = TestEnv::test_data_directory_for_package($pkg);
    my $hash = YAML::LoadFile( File::Spec->join($test_data_dir, 'expected.yml') );
    my $expected_form = slurp( File::Spec->join($test_data_dir, 'expected.form') );
    my $form = $pkg->create($hash);
    is($form, $expected_form, 'submissions form');

};

done_testing();
