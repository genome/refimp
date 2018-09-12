#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Test::Exception;
use Test::More tests => 5;

my %test = ( class => 'Sx::Index::FaiReader', );
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{class}) or die;
    $test{data_dir} = TenxTestEnv::test_data_directory_for_class('Sx::Index::Fai');
    ok(-d $test{data_dir}->stringify, 'data dir exists');

    $test{first_entry} = {
        id => '000000F_001|arrow',
        length => 368138,
        offset =>  19,
        linebases => 60,
        linewidth => 61,
        #qualoffset => ?,
    };

};

subtest 'new' => sub{
    plan tests => 3;

    throws_ok(sub{ $test{class}->new(); }, qr/No index file given/, 'new fails w/o file');
    throws_ok(sub{ $test{class}->new('blah'); }, qr/Index file does not exist/, 'new fails w/ non existing file');

    my $reader = $test{class}->new($test{data_dir}->file('fasta.fai'));
    ok($reader, 'created reader');
    $test{reader} = $reader;

};

subtest 'read' => sub{
    plan tests => 3;

    my $entry = $test{reader}->read;
    ok($entry, 'got entry');
    is_deeply($entry, $test{first_entry}, 'got correct entry');

    my $i = 1;
    while ( $test{reader}->read ) {
        $i++;
    }
    is($i, 6, 'read the correct number of entries');

};

subtest 'reset' => sub{
    plan tests => 3;

    ok(!$test{reader}->read, 'no more entries');
    ok($test{reader}->reset, 'reset');
    is_deeply($test{reader}->read, $test{first_entry}, 'got correct entry');

};

subtest 'seek and tell' => sub{
    plan tests => 4;

    my $position = $test{reader}->tell;
    ok($position, 'tell');
    $test{reader}->seek(0);
    is($test{reader}->tell, 0, 'seek');
    is_deeply($test{reader}->read, $test{first_entry}, 'got correct entry');
    is($test{reader}->tell, $position, 'tell again');

};

done_testing();
