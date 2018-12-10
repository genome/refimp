#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Slurp;
use LWP::UserAgent;
use Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 4;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    $test{pkg} = 'RefImp::Resources::Ncbi::Biosample';
    use_ok($test{pkg}) or die;

    $test{biosample} = 'SAMN06349363';
    $test{bioproject} = 'PRJNA376014';

    $test{ua} = TestEnv::NcbiBiosample->setup;
    ok($test{ua}, 'biosample setup');
    print Data::Dumper::Dumper($test{ua});

};

subtest 'create fails' => sub{
    plan tests => 2;

    throws_ok(sub{ $test{pkg}->create(); }, qr/No bioproject/, 'fails w/o bioproject');
    throws_ok(sub{ $test{pkg}->create(bioproject => $test{bioproject}); }, qr/No biosample/, 'fails w/o biosample');

};

subtest 'create' => sub{
    plan tests => 7;

    my $biosample = $test{pkg}->create(bioproject => $test{bioproject}, biosample => $test{biosample});
    ok($biosample, 'create biosample');
    $test{biosample} = $biosample;

    my $expected_url = sprintf('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?dbfrom=bioproject&db=biosample&id=%s', $biosample->biosample_uid);
    is($biosample->esummary_url, $expected_url, 'correct esummary url');
    $expected_url = sprintf('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=bioproject&db=biosample&id=%s', $biosample->bioproject_uid);
    is($biosample->elink_url, $expected_url, 'correct elink url');

    is($biosample->biosample, 'SAMN06349363', 'biosample');
    is($biosample->biosample_uid, '6349363', 'biosample_uid');
    is($biosample->bioproject, 'PRJNA376014', 'bioproject');
    is($biosample->bioproject_uid, '376014', 'bioproject_uid');

};

subtest 'verify' => sub{
    plan tests => 7;

    my $biosample = $test{biosample};
    $test{ua}->set_response_type('failed');
    throws_ok(sub{ $biosample->verify; }, qr/Failed to GET.+elink/, 'fails when response is not success');

    $test{ua}->set_response_type('no-links');
    ok(!$biosample->verify, 'fails when no links found');
    like($biosample->_error, qr#No bioproject/biosample links found in elink xml#, 'correct error');
    $biosample->_error(undef);

    $test{ua}->set_response_type('no-project-sample-link');
    ok(!$biosample->verify, 'fails when no links found');
    like($biosample->_error, qr#Could not find bioproject/biosample#, 'correct error');
    $biosample->_error(undef);

    $test{ua}->set_response_type('elink');
    ok($biosample->verify, 'verify');
    ok(!$biosample->_error, 'no error set');

};

done_testing();
