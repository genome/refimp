#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;

use File::Compare;
use File::Spec;
use File::Temp;
use Test::More tests => 2;

my $pkg = 'Refimp::Project::Command::Notes::Create';
use_ok($pkg) or die;

subtest 'execute' => sub {
    plan tests => 3;

    my $project = Refimp::Project->create(name => 'H_PROJECT');
    ok($project, 'create project');

    my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
    Refimp::Config::set('seqmgr', $tmpdir);
    mkdir File::Spec->join($tmpdir, $project->name);

    my $notes_file_path = $project->notes_file_path;
    my $fh = IO::File->new($notes_file_path, 'w');
    $fh->print("PREVIOUS CONTENT!\n");
    $fh->close;

    my $cmd = Refimp::Project::Command::Notes::Create->execute(
        projects => [ $project ],
        prefinisher => 'bobama',
    );
    ok($cmd->result, 'execute notes create');
    my $expected_notes_file_path = File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'expected.notes');
    ok(-s $project->notes_file_path, 'notes file created');

};

done_testing();
