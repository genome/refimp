#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use Test::More tests => 2;

my %test;
subtest "setup" => sub{
    plan tests => 3;

    $test{pkg} = 'RefImp::Assembly::Command::Submission::UpdateAccession';
    use_ok($test{pkg}) or die;

    $test{assembly} = RefImp::Assembly->__define__();
    ok($test{assembly}, 'define assembly');
    $test{submission} = RefImp::Assembly::Submission->__define__(assembly => $test{assembly});
    ok($test{submission}, 'define submission');

};

subtest 'update' => sub{
    plan tests => 2;

    my $update = $test{pkg}->execute(
        submission => $test{submission},
        value => 'HNH00',
    );
    ok($update->result, 'execute');

    is($test{submission}->accession_id, 'HNH00', 'set submission accession_id');

};

done_testing();
