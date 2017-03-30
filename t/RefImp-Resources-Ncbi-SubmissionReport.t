#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More;

my %setup;
subtest "setup" => sub{
    plan tests => 3;

    my $pkg = "RefImp::Resources::Ncbi::SubmissionReport";
    use_ok($pkg) or die;
    $setup{file} = File::Spec->join(
        TestEnv::test_data_directory_for_package($pkg),
        "wugsc20160707.HMPB-AAD13A05.phase3.fa2htgs.asn.ac4htgs",
    );

    $setup{project} = RefImp::Project->get(1);
    ok($setup{project}, 'get project');
    $setup{submission} = RefImp::Project::Submission->create(
        project => $setup{project},
        directory => '/tmp',
    );
    ok($setup{submission}, 'creaet submission');

    $setup{report} = {
        source => 'wugsc',
        seqname => 'HMPB-AAD13A05',
        localseqname => 'HMPB-AAD13A05',
        accession => 'AC999999',
        version => '1',
        gi => 1042705582,
        phase => 3,
        notes => 'New',
        crdate => '2016-07-07',
        update => '2016-07-07',
    };

};

subtest "from_file" => sub{
    plan tests => 1;

    my $info = RefImp::Resources::Ncbi::SubmissionReport->from_file($setup{file});
    is_deeply($info, $setup{report}, 'parsed file correctly');

};

done_testing();
