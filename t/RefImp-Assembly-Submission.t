#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Slurp 'slurp';
use File::Spec;
use File::Temp 'tempdir';
use Test::Exception;
use Test::MockObject;
use Test::More tests => 9;

my %setup;
subtest 'setup' => sub{
    plan tests => 3;

    $setup{pkg} = 'RefImp::Assembly::Submission';
    use_ok($setup{pkg}) or die;

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

subtest 'create_from_yml' => sub{
    plan tests => 15;

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
    ok($submission, 'create from yml ');
    ok($submission->assembly, 'create assemby');
    is($submission->biosample, $submission_params->{biosample}, 'set biosample');
    is($submission->bioproject, $submission_params->{bioproject}, 'set bioproject');
    like($submission->submitted_on, qr/^\d{4}\-\d{2}\-\d{2}/, 'set submitted_on');
    ok($submission->taxon, 'taxon via assemby');
    is($submission->version, $submission_params->{version}, 'set version');
    $setup{submission} = $submission;

    ok(UR::Context->commit, 'commit');

};

subtest 'define_from_yml' => sub{
    plan tests => 1;

    my $submission = $setup{pkg}->define_from_yml($setup{submission_yml});
    ok($submission, '__define__ from yml ');

};

subtest 'submission_info' => sub {
    plan tests => 7;

    my $submission = $setup{submission};
    my $info = $submission->submission_info;
    $submission->submission_info(undef);
    throws_ok(sub{ $submission->info_for(); }, qr/No submission info set/, 'info_for fails w/o submission info');
    $submission->submission_info($info);

    is_deeply($submission->submission_info, $setup{submission_params}, 'submission info hash');
    throws_ok(sub{ $submission->info_for; }, qr/No key given/, 'info_for fails w/o key');
    is($submission->info_for('coverage'), '20x', 'info_for coverage');

    throws_ok(sub{ $submission->path_for; }, qr/No key given/, 'path_for fails w/o key');
    my $contigs_file = delete $info->{contigs_file};
    is($submission->path_for('contigs_file'), undef, 'path_for when value is undefined');
    $info->{contigs_file} = $contigs_file;
    is($submission->path_for('contigs_file'), File::Spec->join($submission->directory, 'contigs.bases'), 'path_for contigs_file');

};

subtest 'validate_for_submit' => sub{
    plan tests => 13;

    my $submission = $setup{submission};
    my $info = $submission->submission_info();

    # Submission info requried
    $submission->submission_info({});
    throws_ok(sub{ $submission->validate_for_submit; }, qr/No submission info set/, 'validate_for_submit fails w/o submit info');
    $submission->submission_info($info);
    
    # Assembly method required, and correct format
    my $assembly_method = delete $info->{assembly_method};
    $info->{assembly_method} = 'NO_VDOT';
    throws_ok(sub{ $submission->validate_for_submit; }, qr/Invalid assembly_method/, 'fails w/ invalid assembly_method');
    $info->{assembly_method} = $assembly_method;

    # Release notes required
    my $v = delete $info->{release_notes_file};
    throws_ok(sub{ $submission->validate_for_submit; }, qr/No release_notes_file in submission info/, "validate_for_submit fails w/o release_notes_file");
    $info->{release_notes_file} = 'blah';
    throws_ok(sub{ $submission->validate_for_submit; }, qr/File release_notes_file is defined in submission info, but does not exist/, "validate_for_submit fails w/o release_notes_file");
    $info->{release_notes_file} = $v;

    # If defined, these gotta exist
    $v = delete $info->{contigs_file};
    $info->{contigs_file} = 'blah';
    throws_ok(sub{ $submission->validate_for_submit; }, qr/File contigs_file is defined in submission info, but does not exist/, "validate_for_submit fails w/ non exiting contigs");
    $info->{contigs_file} = $v;

    $info->{supercontigs_file} = 'blah';
    throws_ok(sub{ $submission->validate_for_submit; }, qr/File supercontigs_file is defined in submission info, but does not exist/, "validate_for_submit fails w/ non existing supercontigs");
    delete $info->{supercontigs_file};

    $info->{agp_file} = 'blah';
    throws_ok(sub{ $submission->validate_for_submit; }, qr/File agp_file is defined in submission info, but does not exist/, "validate_for_submit fails w/ non existing agp");
    delete $info->{agp_file};

    # Can't have contigs and supercontigs
    $info->{supercontigs_file} = 'supercontigs.fasta';
    throws_ok(sub{ $submission->validate_for_submit; }, qr/Both contigs and supercontigs files are defined in submission/, "validate_for_submit fails w/ contigs and supercontigs");
    delete $info->{supercontigs_file};

    # Can't have supercontigs and agp
    my $contigs_file = delete $info->{contigs_file};
    $info->{supercontigs_file} = 'supercontigs.fasta';
    $info->{agp_file} = 'supercontigs.agp';
    throws_ok(sub{ $submission->validate_for_submit; }, qr/Supercontigs cannot have an AGP file/, "validate_for_submit fails w/ supercontigs and agp");
    delete $info->{supercontigs_file};
    delete $info->{agp_file};

    # No contigs or supercontigs
    throws_ok(sub{ $submission->validate_for_submit; }, qr/No contigs or supercontigs files set in submission YAML/, "validate_for_submit fails w/o contigs or supercontigs");
    $info->{contigs_file} = $contigs_file;

    # Ok with contigs
    lives_ok(sub{ $submission->validate_for_submit; }, 'validate_for_submit w/ contigs');
    $info->{agp_file} = 'supercontigs.agp';

    # Ok with contigs and agp
    lives_ok(sub{ $submission->validate_for_submit; }, 'validate_for_submit w/ contigs and agp');

    # Ok with supercontigs
    delete $info->{contigs_file};
    delete $info->{agp_file};
    $info->{supercontigs_file} = 'supercontigs.fasta';
    lives_ok(sub{ $submission->validate_for_submit; }, 'validate_for_submit w/ supercontigs');
    $info->{contigs_file} = $contigs_file;
    delete $info->{supercontigs_file};

};

subtest 'validate_for_submit authors and contact' => sub{
    plan tests => 3;

    my $submission = $setup{submission};
    my $info = $submission->submission_info();

    my $authors = delete $info->{authors};
    throws_ok(sub{ $submission->validate_for_submit; }, qr/No authors in submission info/, 'validate_for_submit fails w/o authors');
    $info->{authors} = $authors;

    my $contact = delete $info->{contact};
    throws_ok(sub{ $submission->validate_for_submit; }, qr/No contact in submission info/, 'validate_for_submit fails w/o contact');
    $info->{contact} = join(';', $contact, $contact);
    throws_ok(sub{ $submission->validate_for_submit; }, qr/More than one contact found in submission info/, 'validate_for_submit fails w/ too many contacts');
    $info->{contact} = $contact;

};

subtest 'ncbi_biosample' => sub{
    plan tests => 3;

    my $submission = $setup{submission};
    ok($submission->ncbi_biosample, 'get ncbi_biosample');
    is($submission->bioproject_uid, '376014', 'bioproject_uid fom ncbi_biosample');
    is($submission->biosample_uid, '6349363', 'biosample_uid fom ncbi_biosample');

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
