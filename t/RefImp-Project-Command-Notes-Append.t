#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Compare;
use File::Spec;
use File::Temp;
use Test::More tests => 2;

my $pkg = 'RefImp::Project::Command::Notes::Append';
my ($project);
subtest 'setup' => sub {
    plan tests => 3;

    use_ok($pkg) or die;

    $project = RefImp::Project->create(name => 'H_PROJECT');
    ok($project, 'create project');

    my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
    my $directory = File::Spec->join($tmpdir, $project->name);
    mkdir $directory;
    is($project->directory($directory), $directory, 'set project directory');

};

subtest 'execute' => sub {
    plan tests => 2;

    my $notes_file_path = $project->notes_file_path;
    my $fh = IO::File->new($notes_file_path, 'w');
    $fh->print("\nCLONE= H_PROJECT\n~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~\n\nPREVIOUS CONTENT!\n");
    $fh->close;

    my $cmd = RefImp::Project::Command::Notes::Append->execute(
        projects => [ $project ],
        content => "NEW CONTENT!\n",
    );
    ok($cmd->result, 'execute notes create');
    my $expected_notes_file_path = File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'expected.notes');
    is(File::Compare::compare($project->notes_file_path, $expected_notes_file_path), 0, 'notes file matches');

};

done_testing();
