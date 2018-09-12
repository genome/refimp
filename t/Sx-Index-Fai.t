#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Test::Exception;
use Test::More tests => 5;

my %test = ( class => 'Sx::Index::Fai', );
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{class}) or die;
    $test{data_dir} = TenxTestEnv::test_data_directory_for_class($test{class});
    ok(-d $test{data_dir}->stringify, 'data dir exists');

    $test{entry} = {
        id => '000000F_004|arrow',
        length => 62564,
        offset =>  1068423,
        linebases => 60,
        linewidth => 61,
        #qualoffset => ?,
    };

};

subtest 'new' => sub{
    plan tests => 3;

    throws_ok(sub{ $test{class}->new(); }, qr/No index file given/, 'new fails w/o file');
    throws_ok(sub{ $test{class}->new('blah'); }, qr/Index file does not exist/, 'new fails w/ non existing file');

    my $fai = $test{class}->new($test{data_dir}->file('fasta.fai'));
    ok($fai, 'created fai');
    $test{fai} = $fai;

};

subtest 'attr' => sub{
    plan tests => 2;

    my $fai = $test{fai};
    ok($fai->reader, 'fai reader');
    ok($fai->ids_and_positions, 'ids_and_positions');

};

subtest 'entry_for_id' => sub{
    plan tests => 3;

    my $fai = $test{fai};
    throws_ok(sub{ $fai->entry_for_id; }, qr/No id given/, 'fails w/o id');
    lives_ok(sub{ $fai->entry_for_id('blah'); }, 'ok if id not found');
    my $e = $fai->entry_for_id('000000F_004|arrow');
    is_deeply($e, $test{entry}, 'got entry by id');

};

subtest 'entries_for_id_regex' => sub{
    plan tests => 3;

    my $fai = $test{fai};
    throws_ok(sub{ $fai->entries_for_id_regex; }, qr/No id regex given/, 'fails w/o id regex');
    lives_ok(sub{ $fai->entries_for_id_regex('blah'); }, 'ok if id not found');
    my $expected = [ $fai->entry_for_id('000000F_001|arrow'), $fai->entry_for_id('000000F_004|arrow') ];
    my $got = $fai->entries_for_id_regex('^000000F_00[14]');
    is_deeply($got, $expected, 'got entries by id regex');

};

done_testing();
