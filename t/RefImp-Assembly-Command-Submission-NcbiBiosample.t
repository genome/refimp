#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Test::Exception;
use Test::More tests => 1;

subtest 'execute' => sub {
    plan tests => 4;

    my $pkg = 'RefImp::Assembly::Command::Submission::NcbiBiosample';
    use_ok($pkg) or die;
    use_ok('Util::Tablizer');

    my $err;
    open local(*STDERR), '>', \$err or die $!;
    lives_ok(sub{ $pkg->execute(bioproject => 'PRJNA491715', biosample => 'SAMN10392581'); }, 'execute');
    my @expected_data = (
        [qw/ bioproject PRJNA491715 /],
        [qw/ bioproject_uid 491715 /],
        [qw/ biosample SAMN10392581 /],
        [qw/ biosample_uid 10392581 /],
        ['elink_url', 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=bioproject&db=biosample&id=491715' ],
    );
    is($err, Util::Tablizer->format(\@expected_data), 'correct output');

};

done_testing();
