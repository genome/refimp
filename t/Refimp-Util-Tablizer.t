#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 1;

subtest 'format' => sub {
    plan tests => 4;

    use_ok('RefImp::Util::Tablizer') or die;

    throws_ok(sub{ RefImp::Util::Tablizer->format(); }, qr/No rows given/, 'fails without row arrayref');

    my $table = RefImp::Util::Tablizer->format([]);
    is($table, '', 'formated nothing into nothing');

    my @rows = (
        [qw| aaa AAA-1    /gscmnt/gc0001/info/projects/aaa |],
        [qw| bbb BBB-23   /gscmnt/gc0001/info/projects/bbb |],
        [qw| ccc CCC-9876 /gscmnt/gc0001/info/projects/ccc |],
    );
    my $expected_table = "aaa AAA-1    /gscmnt/gc0001/info/projects/aaa\n";
    $expected_table   .= "bbb BBB-23   /gscmnt/gc0001/info/projects/bbb\n";
    $expected_table   .= "ccc CCC-9876 /gscmnt/gc0001/info/projects/ccc\n";
    $table = RefImp::Util::Tablizer->format(\@rows);
    is($table, $expected_table, 'format');

};

done_testing();
