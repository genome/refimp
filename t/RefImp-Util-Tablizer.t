#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my %test = (
    rows => [
        [qw| aaa AAA-1    /gscmnt/gc0001/info/projects/aaa |],
        [qw| bbb BBB-23   /gscmnt/gc0001/info/projects/bbb |],
        [qw| ccc CCC-9876 /gscmnt/gc0001/info/projects/ccc |],
    ],
);

use_ok('RefImp::Util::Tablizer') or die;

subtest 'format' => sub {
    plan tests => 3;

    throws_ok(sub{ RefImp::Util::Tablizer->format(); }, qr/No rows given/, 'fails without row arrayref');

    my $table = RefImp::Util::Tablizer->format([]);
    is($table, '', 'formated nothing into nothing');

    my $expected_table = "aaa AAA-1    /gscmnt/gc0001/info/projects/aaa\n";
    $expected_table   .= "bbb BBB-23   /gscmnt/gc0001/info/projects/bbb\n";
    $expected_table   .= "ccc CCC-9876 /gscmnt/gc0001/info/projects/ccc\n";
    $table = RefImp::Util::Tablizer->format($test{rows});
    is($table, $expected_table, 'format');

};

subtest 'as html' => sub {
    plan tests => 3;

    throws_ok(sub{ RefImp::Util::Tablizer->format(); }, qr/No rows given/, 'fails without row arrayref');

    my $table = RefImp::Util::Tablizer->format([]);
    is($table, '', 'formated nothing into nothing');

    my $expected_table = "<table><tbody>";
    for my $row ( @{$test{rows}} ) {
        $expected_table .= '<tr>';
        for my $field ( @$row ) {
            $expected_table .= "<td>$field</td>";
        }
        $expected_table .= '</tr>';
    }
    $expected_table .= "</tbody></table>";

    $table = RefImp::Util::Tablizer->as_html($test{rows});
    is($table, $expected_table, 'table matches');

};

done_testing();
