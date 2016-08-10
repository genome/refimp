#!/usr/bin/env lims-perl

use strict;
use warnings;

use above 'RefImp';

use Test::Exception;
use Test::More tests => 3;

use_ok('RefImp::Config') or die;

subtest 'get' => sub{
    plan tests => 3;

    throws_ok(sub{ RefImp::Config::get(); }, qr/No key to get config\!/, 'get without key');
    throws_ok(sub{ RefImp::Config::get('nada'); }, qr/Invalid key to get config\! nada/, 'get with invalid key');
    lives_ok(sub{ RefImp::Config::get('seqmgr'); }, 'get');

};

subtest 'set' => sub{
    plan tests => 5;

    throws_ok(sub{ RefImp::Config::set(); }, qr/No key\/value to set config\!/, 'set with no params');
    throws_ok(sub{ RefImp::Config::set('seqmgr'); }, qr/No value to set config\!/, 'set without value');
    throws_ok(sub{ RefImp::Config::set('nada', 'value'); }, qr/Invalid key to set config\! nada/, 'set with invalid key');
    lives_ok(sub{ RefImp::Config::set('seqmgr', 'value'); }, 'set');
    is(RefImp::Config::get('seqmgr'), 'value', 'set confirmed');

};

done_testing();
