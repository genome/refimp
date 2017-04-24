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

    $setup{pkg} = 'RefImp::Assembly::Submission';
    use_ok($setup{pkg}) or die;

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
    my $xml_file = File::Spec->join(TestEnv::test_data_directory_for_package($setup{pkg}), 'esummary.xml');
    my $xml_content = File::Slurp::slurp($xml_file);
    ok($xml_content, 'loaded xml');

    $setup{response} = Test::MockObject->new();
    $setup{response}->set_true('is_success');
    $setup{response}->set_always('decoded_content', $xml_content);

};

subtest 'create' => sub{
    plan tests => 1;

    $setup{submission} = $setup{pkg}->create(bioproject => 'PRJNA376014');
    ok($setup{submission}, 'create submission');

};

subtest 'ncbi_xml_dom' => sub{
    plan tests => 3;

    my $expected_url = sprintf('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?dbfrom=bioproject&db=biosample&id=%s', $setup{submission}->bioproject);
    $setup{ua}->mock('get', sub{ is($_[1], $expected_url, 'correct url'); $setup{response}; });
    $setup{response}->set_false('is_success');
    throws_ok(sub{ $setup{submission}->ncbi_xml_dom; }, qr/Failed to GET/, 'fails when response is not success');

    $setup{ua}->mock('get', sub{ $setup{response} });
    $setup{response}->set_true('is_success');
    my $dom = $setup{submission}->ncbi_xml_dom;
    ok($dom, 'got ncbi xml dom');

};

done_testing();
