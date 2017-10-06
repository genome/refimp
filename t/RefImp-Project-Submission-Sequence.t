#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use lib '.';


use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 4;

my $pkg = 'RefImp::Project::Submission::Sequence';
use_ok($pkg) or die;

my $ace = File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'HMPB-AAD13A05.fasta.ace.0');
my $project_name = 'HMPB-AAD13A05';

subtest 'fails' => sub{
    plan tests => 8;

    throws_ok(sub{ $pkg->create; }, qr/Mandatory parameters/, 'create w/o params fails');
    throws_ok(sub{ $pkg->create(ace => $ace, project_name => 'HMPB-AAD13A05'); }, qr/Mandatory parameter 'contig_data' missing/, 'create w/o contig_data fails');
    throws_ok(sub{ $pkg->create(ace => $ace, contig_data => [{}],); }, qr/Mandatory parameter 'project_name' missing/, 'create w/o contig_data fails');
    throws_ok(sub{ $pkg->create(contig_data => [{}], project_name => 'HMPB-AAD13A05'); }, qr/Mandatory parameter 'ace' missing/, 'create w/o ace fails');

    throws_ok(sub{ $pkg->create(ace => 'nowaythisexists', contig_data => [{}], project_name => 'HMPB-AAD13A05'); }, qr/Ace file does not exist\! nowaythisexists/, 'create w/ invalid ace fails');

    throws_ok(sub{ $pkg->create(ace => $ace, contig_data => [], project_name => 'HMPB-AAD13A05'); }, qr/No contig_data given\!/, 'create w/o actual contig_data fails');
    throws_ok(sub{ $pkg->create(ace => $ace, contig_data => [qw/ 1 1 /], project_name => 'HMPB-AAD13A05'); }, qr/Not supporting multiple/, 'create w/ >1 contig_data fails');

    throws_ok(
        sub{
            $pkg->create(
                ace => File::Spec->join(TestEnv::test_data_directory_for_package($pkg), 'HMPB-AAD13A05.fasta.ace.with-ambiguous-bases'),
                contig_data => [ { ContigNumber => '1', ContigFinishedFrom => 1, ContigFinishedTo => 1413, }, ],
                project_name => 'HMPB-AAD13A05',
            );
        },
        qr/has ambiguous bases in contig Contig1\!/,
        'contig sequence has ambiguous bases',
    );
};

subtest 'create' => sub{
    plan tests => 6;

    my $sequence = $pkg->create(
        project_name => $project_name,
        ace => $ace,
        contig_data => [ { ContigNumber => '1', ContigFinishedFrom => 1, ContigFinishedTo => 1413, }, ],
    );
    ok($sequence, 'create submissions sequence');

    my $seq = $sequence->seq;
    ok($seq, 'set seq');
    is($seq->display_id, $project_name, 'seq display_id');
    is($seq->desc, '1 to 1413', 'seq desc');
    is($seq->length, 1413, 'seq length');

    is($sequence->transposon_excised_seq, $seq, 'set transposon_excised_seq');

};

subtest 'create with transposons' => sub{
    plan tests => 10;

    my $sequence = $pkg->create(
        project_name => $project_name,
        ace => $ace,
        contig_data => [ { ContigNumber => '1', ContigFinishedFrom => 1, ContigFinishedTo => 1413, }, ],
        transposons => [
            {
                TransposonCommentsSequenceRegion => 'Finished Region',
                TransposonCommentsLastBaseBeforePosition => 100,
                TransposonCommentsFirstBaseAfterPosition => 201,
            },
            {
                TransposonCommentsSequenceRegion => 'Excised',
                TransposonCommentsLastBaseBeforePosition => 500,
                TransposonCommentsFirstBaseAfterPosition => 601,
            },
            {
                TransposonCommentsSequenceRegion => 'Finished Region',
                TransposonCommentsLastBaseBeforePosition => 900,
                TransposonCommentsFirstBaseAfterPosition => 1001,
            },
        ],
    );
    ok($sequence, 'create submissions sequence w/ transposons');

    my $seq = $sequence->seq;
    ok($sequence->seq, 'set seq');
    is($seq->display_id, $project_name, 'seq display_id');
    is($seq->desc, '1 to 1413', 'seq desc');
    is($seq->length, 1413, 'seq length');

    my $transposon_excised_seq = $sequence->transposon_excised_seq;
    ok($transposon_excised_seq, 'set transposon_excised_seq');
    isnt($transposon_excised_seq, $seq, 'transposon_excised_seq is different than seq');
    is($transposon_excised_seq->display_id, $project_name, 'transposon_excised_seq display_id');
    is($transposon_excised_seq->desc, '1 to 100 201 to 900 1001 to 1413', 'transposon_excised_seq desc');
    is($transposon_excised_seq->length, 1213, 'transposon_excised_seq length');

};

done_testing();
