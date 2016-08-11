#!/usr/bin/env lims-perl

use strict;
use warnings;

use above 'RefImp';

use File::Spec qw();
use RefImp::Test::Factory;
use Test::More tests => 6;

use_ok('RefImp::Clone') or die;

my $clone;
subtest "basics" => sub{
    plan tests => 6;

    $clone = RefImp::Test::Factory->setup_test_clone;
    ok($clone, 'got clone');
    ok($clone->name, 'clone has a name');
    ok($clone->type, 'clone has a type');
    ok($clone->status, 'clone has a status');

    my $expected_directory = File::Spec->join( RefImp::Config::get('seqmgr'), $clone->name);
    is($clone->project_directory, $expected_directory, 'project_directory');
    is($clone->project_directory_for_name($clone->name), $expected_directory, 'project_directory_for_name');

};

subtest 'taxonomy' => sub {
    plan tests => 4;

    my $taxon = $clone->taxonomy;
    ok($taxon, 'taxon');
    is($clone->species_name, $taxon->species_name, 'species_name');
    is($clone->species_latin_name,  $taxon->species_latin_name, 'species_latin_name');
    is($clone->chromosome, $taxon->chromosome, 'chromosome');

};

subtest 'notes file' => sub{
    plan tests => 3;

    my $notes_file_path = $clone->notes_file_path;
    ok($notes_file_path, 'notes_file_path');
    ok(-s $notes_file_path, 'notes_file_path exists');
    ok($clone->notes_file, 'notes_file');

};

subtest 'ace0' => sub{
    plan tests => 3;

    my $ace0_path = $clone->ace0_path;
    ok($ace0_path, 'ace0_path');
    like($ace0_path, qr/\.ace\.0$/, 'ace0_path named correctly');
    ok(-s $ace0_path, 'ace0_path exixsts');

};

subtest 'project' => sub{
    plan tests => 3;

    my $project = RefImp::Test::Factory->setup_test_project;
    ok($project, 'got project');
    is($clone->project, $project, 'got project via clone');

    $project->status('new');
    is($clone->project_status, 'new', 'project_status');

};

done_testing();