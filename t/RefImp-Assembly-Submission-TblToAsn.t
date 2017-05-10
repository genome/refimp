#!/usr/bin/env perl5.10.1

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Temp;
use Path::Class 'dir';
use Test::More tests => 3;

my $pkg = 'RefImp::Assembly::Submission::TblToAsn';
my $cmd;
subtest 'setup' => sub {
    plan tests => 4;

    use_ok($pkg) or die;

    my $taxon = RefImp::Taxon->create(name => 'oyster', species_name => 'Crassostrea virginica');
    ok($taxon, 'create taxon');

    my $submission_yml = File::Spec->join(TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission'), 'submission.yml');
    my $submission = RefImp::Assembly::Submission->create_from_yml($submission_yml);
    ok($submission, 'created submission from yml');

    my $tempdir = dir( File::Temp::tempdir(CLEANUP => 1) );
    $cmd = $pkg->create(
        submission => $submission,
        output_directory => $tempdir,
    );
    ok($cmd, 'create command');

};

subtest 'various things' => sub{
    plan tests => 3;

    my $expected_authors = join(
        "\n",
        '{ name name { last "Warren" , first "Wesley" , initials "W.C." } } ,',
        '{ name name { last "Gomez-Chiarri" , first "Marta" , initials "M." } } ,',
        '{ name name { last "Tomlinson" , first "Chad" , initials "C." } } ,',
    );
    is($cmd->submission_authors, $expected_authors, 'formatted_submission_authors');

    my $expected_source_qualifiers = "'[organism=Crassostrea virginica] [tech=wgs]'";
    is($cmd->source_qualifiers, $expected_source_qualifiers, 'source_qualifiers');

    my $expected_structured_comments = "StructuredCommentPrefix	##Genome-Assembly-Data-START##\nAssembly Method	Falcon v. January 2017\nGenome Coverage	20x\nSequencing Technology	PacBio_RSII\n";
    is($cmd->structured_comments, $expected_structured_comments, 'structured_comments');

};

subtest 'execute' => sub{
    plan tests => 3;

    ok($cmd->execute);
    ok($cmd->result, 'execute');

    my $results_path = $cmd->results_path;
    is($cmd->sqn_files, 2, 'sqn_files');

};

done_testing();
