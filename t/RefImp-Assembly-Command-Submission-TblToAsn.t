#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

use File::Temp;
use Test::More tests => 4;

my $pkg = 'RefImp::Assembly::Command::Submission::TblToAsn';
my $cmd;
subtest 'setup' => sub {
    plan tests => 4;

    use_ok($pkg) or die;

    my $submission_yml = File::Spec->join(TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission'), 'submission.yml');
    ok(-s $submission_yml, 'submission yml exists');

    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    $cmd = $pkg->create(
        submission_yml => $submission_yml,
        output_directory => $tempdir,
    );
    ok($cmd, 'create command');

    ok(TestEnv::NcbiBiosample->setup, 'biosample setup');

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
        #'name name { last "Warren" , first "Wesley" , initials "W.C." }',
        #'name name { last "Gomez-Chiarri" , first "Marta" , initials "M." }',
        #'name name { last "Tomlinson" , first "Chad" , initials "C." }',
        'name name { last "Wesley C. Warren" }',
        'name name { last "Marta Gomez-Chiarri" }',
        'name name { last "Chad Tomlinson" }',
    );
    is_deeply([$cmd->format_names( $cmd->submission->info_for('authors') )], \@expected_authors, 'formatted_submission_authors');

    my $expected_source_qualifiers = "'[organism=Crassostrea virginica] [tech=wgs]'";
    is($cmd->source_qualifiers, $expected_source_qualifiers, 'source_qualifiers');

    my $expected_structured_comments = "StructuredCommentPrefix	##Genome-Assembly-Data-START##\nAssembly Method	Falcon v. January 2017\nGenome Coverage	20x\nPolishing Method	Quiver; Pilon\nRelease Date	immediately after processing\nSequencing Technology	PacBio_RSII\n";
    is($cmd->structured_comments, $expected_structured_comments, 'structured_comments');

};

subtest 'tbl2asn_cmd' => sub{
    plan tests => 2;

    my @tbl2asn_cmd = $cmd->tbl2asn_command;
    my @expected_tbl2asn_cmd = (
		"tbl2asn",
		'-p', $cmd->_output_directory->stringify,
        '-r', $cmd->results_path->stringify,
        '-t', $cmd->template_file->stringify,
        '-s',
        '-V', 'vb',
		'-Z', $cmd->discrepancy_report_path,
		'-X', 'AC',
		'-j', $cmd->source_qualifiers,
		'-Y', $cmd->comment_file,
	);
	is_deeply(\@tbl2asn_cmd, \@expected_tbl2asn_cmd, 'tbl2asn command');

	my @tbl2asn_params = (qw/ -a r -l paired_reads /);
	$cmd->submission->add_info_for('tbl2asn_params', join(' ', @tbl2asn_params));
	@tbl2asn_cmd = $cmd->tbl2asn_command;
	push @expected_tbl2asn_cmd, @tbl2asn_params;
    is_deeply(\@tbl2asn_cmd, \@expected_tbl2asn_cmd, 'tbl2asn command w/ additional params');

};

done_testing();
