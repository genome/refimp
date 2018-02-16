#!/usr/bin/env perl

use strict;
use warnings 'FATAL';




use TestEnv;

use Test::Exception;
use Test::More tests => 5;

my $pkg = 'RefImp::Assembly::SubmissionInfo';
use_ok($pkg) or die;

subtest 'submission_info' => sub{
    plan tests => 2;

    my @keys = $pkg->submission_info_keys;
    ok(@keys, 'submission_info_keys');
    @keys = $pkg->submission_info_optional_keys;
    ok(@keys, 'submission_info_optional_keys');

};

subtest 'help' => sub{
    plan tests => 4;

    throws_ok(sub{ $pkg->help_doc_for_attribute() }, qr/but 2 were expected/, 'help_doc_for_attribute fails w/o key');
    throws_ok(sub{ $pkg->help_doc_for_attribute('blah') }, qr/No submission attribute/, 'help_doc_for_attribute fails w/ invalid key');
    ok($pkg->help_doc_for_attribute('assembly_name'), 'help_doc_for_attribute');
    ok($pkg->help_doc_for_attributes, 'help_doc_for_attributes');

};

subtest 'valid release dates' => sub {
    plan tests => 3;

    my @valid_release_dates = $pkg->valid_release_dates;
    ok(@valid_release_dates, 'valid_release_dates');
    ok($pkg->valid_release_date_regexps, 'valid_release_date_regexps');
    is($pkg->default_release_date, $valid_release_dates[0], 'default_release_date');

};

subtest 'attributes for structured comments' => sub{
    plan tests => 2;

    my @attrs = $pkg->required_attributes_for_structured_comments;
    is(@attrs, 4, 'required_attributes_for_structured_comments');
    @attrs = $pkg->optional_attributes_for_structured_comments;
    is(@attrs, 3, 'optional_attributes_for_structured_comments');

};

done_testing();
