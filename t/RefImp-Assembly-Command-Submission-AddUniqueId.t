#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

use File::Temp;
use Path::Class;
use Test::Exception;
use Test::More tests => 3;
use YAML;

my $pkg = 'RefImp::Assembly::Command::Submission::AddUniqueId';
my $submission_yml;
subtest 'setup' => sub {
    plan tests => 3;

    use_ok($pkg) or die;

    my $tempdir = dir( File::Temp::tempdir(CLEANUP => 1) );
    my $existing_yml = File::Spec->join(TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission'), 'submission.yml');
    ok(-s "$existing_yml", 'submission yml exists');

    my $info = YAML::LoadFile("$existing_yml");
    delete $info->{unique_id};
    $submission_yml = $tempdir->file('submission.yml');
    YAML::DumpFile("$submission_yml", $info); 
    ok(-s "$submission_yml", 'wrote new submission info');

};

subtest 'execute' => sub{
    plan tests => 4;

    my $cmd = $pkg->create(
        submission_yml => "$submission_yml",
    );
    ok($cmd, 'create command');
    ok($cmd->execute);
    ok($cmd->result, 'execute');

    my $info = YAML::LoadFile("$submission_yml");
    ok($info->{unique_id}, 'unique id added to submission yml');

};

subtest 'execute w/ existing unique id' => sub{
    plan tests => 2;

    my $cmd = $pkg->create(
        submission_yml => "$submission_yml",
    );
    ok($cmd, 'create command');
    throws_ok(sub{ $cmd->execute; }, qr/Unique id already exists/, 'execute fails w/ wxisting unique id');

};

done_testing();
