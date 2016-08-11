#!/usr/bin/env lims-perl

use strict;
use warnings;

use above 'RefImp';

use Test::Exception;
use Test::MockObject;
use Test::More;
plan tests => 3;

my $class = 'RefImp::Resources::SSO';
use_ok($class) or die;

subtest 'login' => sub{
    plan tests => 2;

    throws_ok(sub{ $class->login(); }, qr/but 2 were expected/, 'login fails w/o url');

    my $url = 'https://rt.gsc.wustl.edu';
    my $sso = $class->login($url);
    ok($sso, 'login'); 

};

subtest 'request_json' => sub{
    plan tests => 5;

    my $user_agent = Test::MockObject->new();
    my $sso = bless { user_agent => $user_agent }, $class;

    my $response = Test::MockObject->new();
    $user_agent->set_always('get', $response);

    # no url
    throws_ok(sub{ $sso->request_json(); }, qr/but 2 were expected/, 'login fails w/o url');

    # failure when response is not success
    $response->set_always('is_success', 0); 
    $response->set_always('status_line', 'FAIL'); 
    throws_ok(sub{ $sso->request_json('url'); }, qr/Failed to get a response/, 'request_json fails when response is not success');

    # response is now success
    $response->set_always('is_success', 1); 

    # failure with invalid json
    $response->set_always('decoded_content', '{"data""/gscmnt/gc9015/info/148854833/2894954039.genotype.normalized"]}');
    throws_ok(sub{ $sso->request_json('url'); }, qr/Failed to decode content to json\!/, 'request_json fails w/ invalid json');

    # success
    $response->set_always('decoded_content', '{"data":["/gscmnt/gc9015/info/148854833/2894954039.genotype.normalized"]}');
    my $data = $sso->request_json('url');
    ok($data, 'request_json success');
    is_deeply(
        $data,
        { data => [qw( /gscmnt/gc9015/info/148854833/2894954039.genotype.normalized )], },
        'data matches',
    );

};

done_testing();
