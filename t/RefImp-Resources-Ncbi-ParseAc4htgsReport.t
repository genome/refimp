#!/usr/bin/env lims-perl

use strict;
use warnings;

use TestEnv;

use Test::More;

my %setup;
subtest "setup" => sub{
    plan tests => 1;

    use_ok("RefImp::Resources::Ncbi::ParseAc4htgsReport") or die;
    $setup{file} = File::Spec->join(
        TestEnv::test_data_directory_for_package("RefImp::Resources::Ncbi::ParseAc4htgsReport"),
        "wugsc20160707.HMPB-AAD13A05.phase3.fa2htgs.asn.ac4htgs",
    );

};

subtest "parse" => sub{
    plan tests => 1;

    my $info = RefImp::Resources::Ncbi::ParseAc4htgsReport->parse($setup{file});
    my $expected_info = {
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
    is_deeply($info, $expected_info, 'parsed file correctly');

};

done_testing();

