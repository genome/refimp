#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Test::More tests => 3;
use Test::Exception;

use TenxTestEnv;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    %test = ( class => 'Tenx::Util::Reader' );
    use_ok($test{class});

};

subtest 'fails' => sub{
    plan tests => 1;

    throws_ok(sub{ $test{class}->new; }, qr/No location given/, 'fails w/o location');

};

subtest 'attributes' => sub{
    plan tests => 3;

    my $reader = bless { location => 'l', handle => 'h' }, $test{class};
    ok($reader, 'new reader');
    is($reader->location, 'l', 'reader location');
    is($reader->handle, 'h', 'reader handle');

};

done_testing();
