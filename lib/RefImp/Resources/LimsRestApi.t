#!/usr/bin/env lims-perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
}

use strict;
use warnings 'FATAL';

use above 'RefImp';

require Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 5;

my $class = 'RefImp::Resources::LimsRestApi';
use_ok($class) or die;

my $lims_rest_api = $class->new();
ok($lims_rest_api, 'create lims_rest_api');

my $clone = RefImp::Clone->create(name => 'HMPB-AAD13A05');

subtest 'resolve_gsc_class_for_object' => sub{
    plan tests => 3;

    throws_ok(sub{ $class->resolve_gsc_class_for_object(); }, qr/but 2 were expected/, 'fails w/o object');
    throws_ok(sub{ $class->resolve_gsc_class_for_object(Test::MockObject->new); }, qr/was not a 'UR::Object'/, 'fails w/ non UR::Object class');

    is( # solexa
        $class->resolve_gsc_class_for_object($clone),
        'GSC::Clone',
        'RefImp::Clone returns GSC::Clone',
    );

};

subtest 'url_for_object_and_method' => sub{
    plan tests => 3;

    throws_ok(sub{ $class->url_for_object_and_method(); }, qr/but 3 were expected/, 'fails w/o object');
    throws_ok(sub{ $class->url_for_object_and_method($clone); }, qr/but 3 were expected/, 'fails w/o method');

    my $method = 'name';
    my $url = $class->url_for_object_and_method($clone, $method);
    my $expected_url = sprintf(
        '%sapp?json={"object":{"class":"%s","id":"%s"},"method":"%s"}',
        $class->imp_lims_url,
        $class->resolve_gsc_class_for_object($clone),
        $clone->id,
        $method,
    );
    is($url, $expected_url, 'correct url');

};

subtest 'query' => sub{
    plan tests => 3;

    throws_ok(sub{ $class->url_for_object_and_method(); }, qr/but 3 were expected/, 'fails w/o clone');
    throws_ok(sub{ $class->url_for_object_and_method($clone); }, qr/but 3 were expected/, 'fails w/o method');
    
    my $user_agent = Test::MockObject->new();
    my $sso = Test::MockObject->new();
    $sso->set_always('user_agent', $user_agent);
    my $lims_rest_api = bless { sso => $sso }, $class;
    my $json = JSON->new->allow_nonref;

    my $data = $json->decode( sprintf('{"data":["%s"]}', $clone->name) );
    $sso->set_always('request_json', $data);
    my $method = 'name';
    my $value = $lims_rest_api->query($clone, $method);
    is($value, $clone->name, 'query clone name');

};

done_testing();
