#!/usr/bin/env refimp-perl

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

    $setup{pkg} = 'Refimp::Resources::Ncbi::Biosample';
    use_ok($setup{pkg}) or die;

    # Bioproject/sample
    $setup{biosample} = 'SAMN06349363';
    $setup{bioproject} = 'PRJNA376014';

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
    my $type = 'elink';
    my $xml_file = File::Spec->join(TestEnv::test_data_directory_for_package($setup{pkg}), join('.', $type, 'xml'));
    my $xml = File::Slurp::slurp($xml_file);
    ok($xml, "loaded $type xml");

    my $response = Test::MockObject->new();
    $response->set_always('decoded_content', $xml);
    $setup{ join('_', 'response', $type) } = $response;

    # Return response based on URL
    $setup{ua}->mock('get', sub{ $setup{response_elink}; });

};

subtest 'create fails' => sub{
    plan tests => 3;

    throws_ok(sub{ $setup{pkg}->create(); }, qr/No bioproject/, 'fails w/o bioproject');
    throws_ok(sub{ $setup{pkg}->create(bioproject => $setup{bioproject}); }, qr/No biosample/, 'fails w/o biosample');

    $setup{response_elink}->set_false('is_success');
    throws_ok(sub{ $setup{pkg}->create(bioproject => $setup{bioproject}, biosample => $setup{biosample}); }, qr/Failed to GET.+elink/, 'fails when elink response is not success');
    $setup{response_elink}->set_true('is_success');

};

subtest 'create' => sub{
    plan tests => 7;

    my $biosample = $setup{pkg}->create(bioproject => $setup{bioproject}, biosample => $setup{biosample});
    ok($biosample, 'create biosample');

    my $expected_url = sprintf('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?dbfrom=bioproject&db=biosample&id=%s', $biosample->biosample_uid);
    is($biosample->esummary_url, $expected_url, 'correct esummary url');
    $expected_url = sprintf('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=bioproject&db=biosample&id=%s', $biosample->bioproject_uid);
    is($biosample->elink_url, $expected_url, 'correct elink url');

    is($biosample->biosample, 'SAMN06349363', 'biosample');
    is($biosample->biosample_uid, '6349363', 'biosample_uid');
    is($biosample->bioproject, 'PRJNA376014', 'bioproject');
    is($biosample->bioproject_uid, '376014', 'bioproject_uid');

};

done_testing();
