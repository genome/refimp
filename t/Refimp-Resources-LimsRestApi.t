#!/usr/bin/env refimp-perl

use strict;
use warnings 'FATAL';

use TestEnv;

require Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 4;

my $class = 'Refimp::Resources::LimsRestApi';
my $project;
subtest 'setup' => sub{
    plan tests => 1;

    use_ok($class) or die;

    my $sso = Test::MockObject->new();
    Sub::Install::reinstall_sub({
            code => sub{ $sso },
            into => 'Refimp::Resources::SSO',
            as => 'login',
        });

    my $user_agent = Test::MockObject->new();
    $sso->set_always('user_agent', $user_agent);

    $project = Refimp::Project->create(name => 'HMPB-AAD13A05');

    my $json = JSON->new->allow_nonref;
    my $data = $json->decode( sprintf('{"data":["%s"]}', $project->name) );
    $sso->set_always('request_json', $data);

};

subtest 'resolve_gsc_class_for_object' => sub{
    plan tests => 3;

    throws_ok(sub{ $class->resolve_gsc_class_for_object(); }, qr/but 2 were expected/, 'fails w/o object');
    throws_ok(sub{ $class->resolve_gsc_class_for_object(Test::MockObject->new); }, qr/was not a 'UR::Object'/, 'fails w/ non UR::Object class');

    is( # solexa
        $class->resolve_gsc_class_for_object($project),
        'GSC::Project',
        'Refimp::Project returns GSC::Project',
    );

};

subtest 'url_for_object_and_method' => sub{
    plan tests => 3;

    throws_ok(sub{ $class->url_for_object_and_method(); }, qr/but 3 were expected/, 'fails w/o object');
    throws_ok(sub{ $class->url_for_object_and_method($project); }, qr/but 3 were expected/, 'fails w/o method');

    my $method = 'name';
    my $url = $class->url_for_object_and_method($project, $method);
    my $expected_url = sprintf(
        '%sapp?json={"object":{"class":"%s","id":"%s"},"method":"%s"}',
        $class->imp_lims_url,
        $class->resolve_gsc_class_for_object($project),
        $project->id,
        $method,
    );
    is($url, $expected_url, 'correct url');

};

subtest 'query' => sub{
    plan tests => 4;

    throws_ok(sub{ $class->url_for_object_and_method(); }, qr/but 3 were expected/, 'fails w/o clone');
    throws_ok(sub{ $class->url_for_object_and_method($project); }, qr/but 3 were expected/, 'fails w/o method');
    
    my $lims_rest_api = $class->new();
    ok($lims_rest_api, 'create lims_rest_api');
    my $value = $lims_rest_api->query($project, 'name');
    is($value, $project->name, 'query clone name');

};

done_testing();
