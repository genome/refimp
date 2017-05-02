#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Spec;
use File::Temp;
use Test::Exception;
use Test::More tests => 4;

my %setup;
subtest 'create' => sub{
    plan tests => 3;

    $setup{pkg} = 'RefImp::Assembly::Submission';
    use_ok($setup{pkg}) or die;

    $setup{submission_yml} = File::Spec->join(TestEnv::test_data_directory_for_package($setup{pkg}), 'submission.yml');
    ok(-s $setup{submission_yml}, 'submission_yml exists');
    $setup{submission_params} = YAML::LoadFile($setup{submission_yml});
    $setup{tempdir} = File::Temp::tempdir(CLEANUP => 1);
    $setup{invalid_submission_yml} = File::Spec->join($setup{tempdir}, 'invalid_submission.yml');

    ok(UR::Context->commit, 'commit');
};

subtest 'valid release dates' => sub {
    plan tests => 3;

    my @valid_release_dates = $setup{pkg}->valid_release_dates;
    ok(@valid_release_dates, 'valid_release_dates');
    ok($setup{pkg}->valid_release_date_regexps, 'valid_release_date_regexps');
    is($setup{pkg}->default_release_date, $valid_release_dates[0], 'default_release_date');

};

subtest 'create_from_yml' => sub{
    plan tests => 11;

    throws_ok(sub{ $setup{pkg}->create_from_yml(); }, qr/No submission YAML given/, 'create_from_yml fails w/o submission yml');
    throws_ok(sub{ $setup{pkg}->create_from_yml('/blah'); }, qr/Submission YAML does not exist/, 'create_from_yml fails w/ non existing submission yml');

    my $submission_params = $setup{submission_params};
    for my $k (qw/ biosample bioproject version /) {
        my $v = delete $submission_params->{$k};
        #unlink $submission_yml;
        YAML::DumpFile($setup{invalid_submission_yml}, $submission_params);
        my $submission = $setup{pkg}->create_from_yml($setup{invalid_submission_yml});
        my @errors = $submission->__errors__;
        like($errors[0]->__display_name__, qr/$k': No value specified/, "create_from_yml fails w/o $k");
        $submission_params->{$k} = $v;
        $submission->delete;
    }

    my $submission = $setup{pkg}->create_from_yml($setup{submission_yml});
    ok($submission, 'create from yml fails w/o submission yml');
    is($submission->biosample, $submission_params->{biosample}, 'set biosample');
    is($submission->bioproject, $submission_params->{bioproject}, 'set bioproject');
    like($submission->submitted_on, qr/^\d{4}\-\d{2}\-\d{2}/, 'set submitted_on');
    is($submission->version, $submission_params->{version}, 'set version');
    $setup{submission} = $submission;

    ok(UR::Context->commit, 'commit');

};

subtest 'submission_info' => sub {
    plan tests => 3;

    is_deeply($setup{submission}->submission_info, $setup{submission_params}, 'submission info hash');
    throws_ok(sub{ $setup{submission}->info_for; }, qr/No key given/, 'info_for fails w/o key');
    is($setup{submission}->info_for('coverage'), '20X', 'info_for coverage');

};

done_testing();
