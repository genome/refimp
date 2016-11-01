#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use File::Compare;
use File::Spec;
use File::Temp;
use TestEnv;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::Command::Digest::ToConsed';
use_ok($pkg) or die;

subtest 'execute' => sub{
    plan tests => 7;

    my $project = RefImp::Project->create(name => 'TEST-AAD13A05');
    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    $project->directory($tempdir);

    my $data_directory = TestEnv::test_data_directory_for_package($pkg);
    my @digest_dates = (qw/ 150421a 160421 /);
    for my $digest_date ( @digest_dates ) {
        my $sizes_file_name = $digest_date.'.sizes';

        my $sizes_file = File::Spec->join($data_directory, $sizes_file_name);
        my $project_sizes_link = File::Spec->join($project->digest_directory, $sizes_file_name);
        symlink($sizes_file, $project_sizes_link);
        ok(-e $project_sizes_link, 'linked sizes file');
    }

    my $sz2consed = $pkg->create(project => $project);
    ok($sz2consed->execute, 'execute');

    for my $digest_date ( @digest_dates ) {
        my $frag_sizes_name = 'fragSizes'.$digest_date.'.txt';
        my $expected_frag_sizes_file = File::Spec->join($data_directory, $frag_sizes_name);
        my $project_frag_sizes_file = File::Spec->join($project->edit_directory, $frag_sizes_name);
        is(File::Compare::compare($project_frag_sizes_file, $expected_frag_sizes_file), 0, "$frag_sizes_name matches");
    }

    my $project_frag_sizes_link = File::Spec->join($project->edit_directory, 'fragSizes.txt');
    ok(-l $project_frag_sizes_link, 'linked fragSizes.txt');

    my $expected_most_recent_frag_sizes_file = File::Spec->join($data_directory, 'fragSizes'.$digest_dates[1].'.txt');
    is(File::Compare::compare($project_frag_sizes_link, $expected_most_recent_frag_sizes_file), 0, 'fragSizes.txt matches most recent');

};

done_testing();
