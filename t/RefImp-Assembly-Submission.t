#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Test::More tests => 2;

my $pkg = 'RefImp::Assembly::Submission';
subtest 'create' => sub{
    plan tests => 4;

    use_ok($pkg) or die;

    my %params = (
        bioproject => 'PRJNA376014',
        biosample => 'SAMN06349363',
        version => { is => 'Text', doc => 'NCBI formatted assembly version', },
        submission_yml => { is => 'Text', doc => 'YAML file with submission information', },
    );
    my $submission = $pkg->create(%params);
    ok($submission, 'create submission');
    like($submission->submitted_on, qr/^\d{4}\-\d{2}\-\d{2}/, 'set submitted_on');

    ok(UR::Context->commit, 'commit');
};

subtest 'valid release dates' => sub {
    plan tests => 3;

    my @valid_release_dates = $pkg->valid_release_dates;
    ok(@valid_release_dates, 'valid_release_dates');
    ok($pkg->valid_release_date_regexps, 'valid_release_date_regexps');
    is($pkg->default_release_date, $valid_release_dates[0], 'default_release_date');

};

done_testing();
