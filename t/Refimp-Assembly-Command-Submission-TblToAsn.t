#!/usr/bin/env refimp-perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Temp;
use Test::More tests => 3;

my $pkg = 'Refimp::Assembly::Command::Submission::TblToAsn';
my $cmd;
subtest 'setup' => sub {
    plan tests => 3;

    use_ok($pkg) or die;

    my $submission_yml = File::Spec->join(TestEnv::test_data_directory_for_package('Refimp::Assembly::Submission'), 'submission.yml');
    ok(-s $submission_yml, 'submission yml exists');

    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    $cmd = $pkg->create(
        submission_yml => $submission_yml,
        output_directory => $tempdir,
    );
    ok($cmd, 'create command');

};

subtest 'execute' => sub{
    plan tests => 3;

    ok($cmd->execute);
    ok($cmd->result, 'execute');

    my $results_path = $cmd->results_path;
    is_deeply([$cmd->sqn_files], [File::Spec->join($cmd->results_path, 'contigs.01.sqn')], 'sqn_files');

};

subtest 'authors, qualifiers, and comments' => sub{
    plan tests => 3;

    my @expected_authors = (
        'name name { last "Warren" , first "Wesley" , initials "W.C." }',
        'name name { last "Gomez-Chiarri" , first "Marta" , initials "M." }',
        'name name { last "Tomlinson" , first "Chad" , initials "C." }',
    );
    is_deeply([$cmd->format_names( $cmd->submission->info_for('authors') )], \@expected_authors, 'formatted_submission_authors');

    my $expected_source_qualifiers = "'[organism=Crassostrea virginica] [tech=wgs]'";
    is($cmd->source_qualifiers, $expected_source_qualifiers, 'source_qualifiers');

    my $expected_structured_comments = "StructuredCommentPrefix	##Genome-Assembly-Data-START##\nAssembly Method	Falcon v. January 2017\nGenome Coverage	20x\nPolishing Method	Quiver; Pilon\nSequencing Technology	PacBio_RSII\n";
    is($cmd->structured_comments, $expected_structured_comments, 'structured_comments');

};

done_testing();
