#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Slurp 'slurp';
use File::Spec;
use File::Temp 'tempdir';
use Test::Exception;
use Test::MockObject;
use Test::More tests => 8;

my %setup;
subtest 'setup' => sub{
    plan tests => 4;

    $setup{pkg} = 'RefImp::Assembly::Submission';
    use_ok($setup{pkg}) or die;

    my $taxon = RefImp::Taxon->create(name => 'oyster', species_name => 'Crassostrea virginica');
    ok($taxon, 'create taxon');

    my $data_dir = TestEnv::test_data_directory_for_package($setup{pkg});
    $setup{submission_yml} = File::Spec->join($data_dir, 'submission.yml');
    ok(-s $setup{submission_yml}, 'submission_yml exists');
    $setup{submission_params} = YAML::LoadFile($setup{submission_yml});
    $setup{tempdir} = tempdir(CLEANUP => 1);
    $setup{invalid_submission_yml} = File::Spec->join($setup{tempdir}, 'invalid_submission.yml');

    $setup{ua} = Test::MockObject->new();
    $setup{ua}->set_true('timeout');
    $setup{ua}->set_true('env_proxy');

    Sub::Install::reinstall_sub({
        code => sub{ $setup{ua} },
        into => 'LWP::UserAgent',
        as => 'new',
        });

    # Load XML, set as decoded content
    my $xml_file = File::Spec->join($data_dir, 'esummary.xml');
    my $xml_content = slurp($xml_file);
    ok($xml_content, 'loaded xml');

    $setup{response} = Test::MockObject->new();
    $setup{response}->set_true('is_success');
    $setup{response}->set_always('decoded_content', $xml_content);
    $setup{ua}->set_always('get', $setup{response});

};

subtest 'valid release dates' => sub {
    plan tests => 3;

    my @valid_release_dates = $setup{pkg}->valid_release_dates;
    ok(@valid_release_dates, 'valid_release_dates');
    ok($setup{pkg}->valid_release_date_regexps, 'valid_release_date_regexps');
    is($setup{pkg}->default_release_date, $valid_release_dates[0], 'default_release_date');

};

subtest 'create_from_yml' => sub{
    plan tests => 13;

    throws_ok(sub{ $setup{pkg}->create_from_yml(); }, qr/No submission YAML given/, 'create_from_yml fails w/o submission yml');
    throws_ok(sub{ $setup{pkg}->create_from_yml('/blah'); }, qr/Submission YAML does not exist/, 'create_from_yml fails w/ non existing submission yml');

    my $submission_params = $setup{submission_params};
    for my $k (qw/ biosample bioproject version /) {
        my $v = delete $submission_params->{$k};
        YAML::DumpFile($setup{invalid_submission_yml}, $submission_params);
        my $submission = $setup{pkg}->create_from_yml($setup{invalid_submission_yml});
        my @errors = $submission->__errors__;
        like($errors[0]->__display_name__, qr/$k': No value specified/, "create_from_yml fails w/o $k");
        $submission_params->{$k} = $v;
        $submission->delete;
    }

    my $taxon = delete $submission_params->{taxon};
    YAML::DumpFile($setup{invalid_submission_yml}, $submission_params);
    throws_ok(sub{ $setup{pkg}->create_from_yml($setup{invalid_submission_yml}); }, qr/No taxon in submission YAML/, 'fails w/o taxon');
    $submission_params->{taxon} = 'i dunno';
    YAML::DumpFile($setup{invalid_submission_yml}, $submission_params);
    throws_ok(sub{ $setup{pkg}->create_from_yml($setup{invalid_submission_yml}); }, qr/Taxon not found for "i dunno"/, 'fails when taxon not found');
    $submission_params->{taxon} = $taxon;


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
    plan tests => 6;

    my $submission = $setup{submission};
    my $info = $submission->submission_info;
    $submission->submission_info(undef);
    throws_ok(sub{ $submission->info_for(); }, qr/No submission info set/, 'info_for fails w/o submission info');
    $submission->submission_info($info);

    is_deeply($submission->submission_info, $setup{submission_params}, 'submission info hash');
    throws_ok(sub{ $submission->info_for; }, qr/No key given/, 'info_for fails w/o key');
    is($submission->info_for('coverage'), '20X', 'info_for coverage');

    throws_ok(sub{ $submission->path_for; }, qr/No key given/, 'path_for fails w/o key');
    is($submission->path_for('agp_file'), File::Spec->join($submission->directory, 'supercontigs.agp'), 'path_for agp_file');

};

subtest 'validate_for_submit' => sub{
    plan tests => 7;

    my $submission = $setup{submission};
    my $info = $submission->submission_info();
    $submission->submission_info({});
    throws_ok(sub{ $submission->validate_for_submit; }, qr/No submission info set/, 'validate_for_submit fails w/o submit info');
    
    $submission->submission_info($info);
    for my $k (qw/ agp_file contigs_file supercontigs_file /) {
        my $v = delete $info->{$k};
        throws_ok(sub{ $submission->validate_for_submit; }, qr/No $k in submission info/, "validate_for_submit fails w/o $k");
        $info->{$k} = '/blah';
        throws_ok(sub{ $submission->validate_for_submit; }, qr/File $k in submission info not exist/, "validate_for_submit fails w/ non existing $k");
        $info->{$k} = $v;
    }

};

subtest 'esummary' => sub{
    plan tests => 3;

    my $submission = $setup{submission};
    ok($submission->esummary, 'get esummary');
    is($submission->bioproject_uid, '376014', 'bioproject_uid fom esummary');
    is($submission->biosample_uid, '6349363', 'biosample_uid fom esummary');

};

subtest 'release_notes' => sub{
    plan tests => 1;

    my $submission = $setup{submission};
    my $release_notes = $submission->release_notes;
    like($release_notes, qr/^Crassostrea virginica sequence assembly release C_virginica-1\.0 notes/, 'release_notes');

};

subtest 'ncbi_version' => sub{
    plan tests => 1;

    my $submission = $setup{submission};
    is($submission->ncbi_version, 'Crassostrea_virginica_2.0', 'ncbi_version');

};

done_testing();
