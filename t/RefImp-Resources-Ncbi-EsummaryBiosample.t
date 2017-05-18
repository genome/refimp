#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Slurp;
use LWP::UserAgent;
use Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 3;

my %setup;
subtest 'setup' => sub{
    plan tests => 2;

    $setup{pkg} = 'RefImp::Resources::Ncbi::EsummaryBiosample';
    use_ok($setup{pkg}) or die;

    # Biosample
    $setup{biosample} = 'SAMN06349363';
    $setup{biosample_uid} = '6349363';

    # User Agent
    $setup{ua} = Test::MockObject->new();
    $setup{ua}->set_true('timeout');
    $setup{ua}->set_true('env_proxy');

    Sub::Install::reinstall_sub({
        code => sub{ $setup{ua} },
        into => 'LWP::UserAgent',
        as => 'new',
        });

    # Load XML, set as decoded content
    my $xml_file = File::Spec->join(TestEnv::test_data_directory_for_package($setup{pkg}), join('.', 'esummary', $setup{biosample}, 'xml'));
    my $xml_content = File::Slurp::slurp($xml_file);
    ok($xml_content, 'loaded xml');

    $setup{response} = Test::MockObject->new();
    $setup{response}->set_always('decoded_content', $xml_content);
    $setup{ua}->mock('get', sub{ $setup{response} });

};

subtest 'create fails' => sub{
    plan tests => 2;

    throws_ok(sub{ $setup{pkg}->create; }, qr/No biosample/, 'fails w/o biosample');

    $setup{response}->set_false('is_success');
    throws_ok(sub{ $setup{pkg}->create; }, qr/No biosample/, 'fails when response is not success');
    $setup{response}->set_true('is_success');

};

subtest 'create' => sub{
    plan tests => 7;

    my $esummary = $setup{pkg}->create(biosample => $setup{biosample});
    ok($esummary, 'create biosample esummary');

    my $expected_url = sprintf('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?dbfrom=bioproject&db=biosample&id=%s', $setup{biosample_uid});
    is($esummary->eutils_biosample_url, $expected_url, 'correct url');

    is($esummary->biosample, 'SAMN06349363', 'biosample');
    is($esummary->biosample_uid, $setup{biosample_uid}, 'biosample_uid');
    is($esummary->bioproject, 'PRJNA376014', 'bioproject');
    is($esummary->bioproject_uid, '376014', 'bioproject_uid');
    is($esummary->project_title, 'Invertebrate sample from Crassostrea virginica', 'project_title');

};

done_testing();
