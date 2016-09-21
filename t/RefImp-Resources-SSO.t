#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::MockObject;
use Test::More tests => 2;

my $class = 'RefImp::Resources::SSO';
subtest 'setup' => sub{
    plan tests => 1;

    use_ok($class) or die;

    my $mech = Test::MockObject->new;
    $mech->set_true('get');
    $mech->mock('submit_form', sub{});
    $mech->set_true('submit');

    Sub::Install::reinstall_sub({
            code => sub { $mech },
            into => 'WWW::Mechanize',
            as => 'new',
        });

    my $uri = Test::MockObject->new;
    $uri->set_always('host', 'sso.gsc.wustl.edu');
    $mech->set_always('uri', $uri);

    my $ua = Test::MockObject->new;
    $ua->set_true('timeout');
    $ua->set_true('env_proxy');
    $ua->set_true('cookie_jar');

    Sub::Install::reinstall_sub({
            code => sub { $ua },
            into => 'LWP::UserAgent',
            as => 'new',
        });

    RefImp::Config::set('rt_login', 'rt-login');
    RefImp::Config::set('rt_auth', 'rt-auth');

};

subtest 'request_json' => sub{
    plan tests => 7;

    throws_ok(sub{ $class->login(); }, qr/but 2 were expected/, 'login fails w/o url');

    my $sso =  $class->login('url');
    ok($sso, 'login');

    my $user_agent = $sso->user_agent;
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
