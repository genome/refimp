#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use File::Spec;
use File::Temp;
use Test::More tests => 2;
use YAML 'LoadFile';

my $pkg = 'RefImp::Clone::Submissions::Asn';
use_ok($pkg) or die;

subtest 'create' => sub{
    plan tests => 3;

    my $data_dir = TestEnv::test_data_directory_for_package($pkg);
    TestEnv::Clone::setup_test_lims_rest_api;

    my $clone = RefImp::Clone->get(1);
    my $clone_name = $clone->name;
    my $submit_info = LoadFile( File::Spec->join($data_dir, 'HMPB-AAD13A05.yml') );
    #use Storable; my $submit_info = retrieve( File::Spec->join($data_dir, "$clone_name.serialized.dat") );

    my $working_directory = File::Temp::tempdir(CLEANUP => 1);
    symlink File::Spec->join($data_dir, "$clone_name.seq"), File::Spec->join($working_directory, "$clone_name.seq");

    RefImp::User->create(unix_login => 'bobama', first_name => 'barack', last_name => 'obama');
    RefImp::User->create(unix_login => 'jbiden', first_name => 'joe', last_name => 'biden');

    my $asn = $pkg->create(
        clone => $clone,
        submit_info => $submit_info,
        working_directory => $working_directory,
    );
    ok($asn, 'create');
    $asn->generate;
    ok(-s $asn->template_path, 'template_path created'); # date is on file, need way to compare...
    ok(-s $asn->asn_path, 'asn_path created'); # date is on file, need way to compare...

};

done_testing();
