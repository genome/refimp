#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use File::Slurp 'slurp';
use File::Spec;
use File::Temp 'tempdir';
use LWP::UserAgent;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 14;

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

    ok(TestEnv::NcbiBiosample->setup, 'biosample setup');

};

subtest '_from_yml fails' => sub{
    plan tests => 8;

    throws_ok(sub{ $setup{pkg}->_from_yml(); }, qr/No submission YAML given/, 'get_or_create_from_yml fails w/o submission yml');
    throws_ok(sub{ $setup{pkg}->_from_yml('/blah'); }, qr/Submission YAML does not exist/, 'get_or_create_from_yml fails w/ non existing submission yml');

    my %params = %{$setup{submission_params}};
    $params{unique_id} = 'GGG';
    YAML::DumpFile($setup{invalid_submission_yml}, \%params);
    throws_ok(sub{ $setup{pkg}->_from_yml($setup{invalid_submission_yml}); }, qr/Invalid unique_id in YAML: GGG. Please use \'refimp assembly submission add-unique-id\'/, 'fails w/ invalid unique_id');

    %params = %{$setup{submission_params}};
    for my $k (qw/ biosample bioproject version /) {
        my $v = delete $params{$k};
        YAML::DumpFile($setup{invalid_submission_yml}, \%params);
        my $submission = $setup{pkg}->_from_yml($setup{invalid_submission_yml});
        my @errors = $submission->__errors__;
        like($errors[0]->__display_name__, qr/$k': No value specified/, "get_or_create_from_yml fails w/o $k");
        $params{$k} = $v;
        $submission->delete;
    }

    %params = %{$setup{submission_params}};
    my $taxon = delete $params{taxon};
    YAML::DumpFile($setup{invalid_submission_yml}, \%params);
    throws_ok(sub{ $setup{pkg}->_from_yml($setup{invalid_submission_yml}); }, qr/No taxon in submission YAML/, 'fails w/o taxon');
    $params{taxon} = 'i dunno';
    YAML::DumpFile($setup{invalid_submission_yml}, \%params);
    throws_ok(sub{ $setup{pkg}->_from_yml($setup{invalid_submission_yml}); }, qr/Taxon not found for "i dunno"/, 'fails when taxon not found');

};

subtest 'get_or_create_from_yml' => sub{
    plan tests => 12;

    my %params = %{$setup{submission_params}};
    ok($params{unique_id}, 'subimssion params has unique_id');
    my $submission = $setup{pkg}->get($params{unique_id});
    ok(!$submission, 'submission does not exist');

    $submission = $setup{pkg}->get_or_create_from_yml($setup{submission_yml});
    ok($submission, 'create from yml ');
    ok($submission->assembly, 'create assemby');
    is($submission->biosample, $params{biosample}, 'set biosample');
    is($submission->bioproject, $params{bioproject}, 'set bioproject');
    ok($submission->ncbi_biosample, 'set ncbi_bioproject');
    like($submission->submitted_on, qr/^\d{4}\-\d{2}\-\d{2}/, 'set submitted_on');
    ok($submission->taxon, 'taxon via assemby');
    is($submission->version, $params{version}, 'set version');
    $setup{submission} = $submission;
    is($submission->id, $params{unique_id}, 'id is unique_id');

    ok(UR::Context->commit, 'commit');

};

subtest 'get_or_define_from_yml' => sub{
    plan tests => 3;

    my %params = %{$setup{submission_params}};
    $params{unique_id} = UR::Object::Type->autogenerate_new_object_id_uuid;
    YAML::DumpFile($setup{invalid_submission_yml}, \%params);

    my $submission = $setup{pkg}->get_or_define_from_yml($setup{invalid_submission_yml});
    ok($submission, 'get_or_define_from_yml');
    ok($submission->{__defined}, '__define__ submission');
    isnt($submission->id, $setup{submission}->id, 'defined a new subimssion');

};

subtest 'get' => sub{
    plan tests => 1;

    my $submission = $setup{pkg}->get($setup{submission_params}->{unique_id});
    is($submission, $setup{submission}, 'get');

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
    is($submission->info_for('genome_coverage'), '20x', 'info_for coverage');

    throws_ok(sub{ $submission->path_for; }, qr/No key given/, 'path_for fails w/o key');
    my $contigs_file = delete $info->{contigs_file};
    is($submission->path_for('contigs_file'), undef, 'path_for when value is undefined');
    $info->{contigs_file} = $contigs_file;
    is($submission->path_for('contigs_file'), File::Spec->join($submission->directory, 'contigs.bases'), 'path_for contigs_file');

};

subtest 'validate_for_submit' => sub{
    plan tests => 16;

    my $submission = $setup{submission};
    my $info = $submission->submission_info();

    # Submission info requried
    $submission->submission_info({});
    throws_ok(sub{ $submission->validate_for_submit; }, qr/No submission info set/, 'validate_for_submit fails w/o submit info');
    $submission->submission_info($info);
    
    # Authors required, format
    my $v = delete $info->{authors};
    throws_ok(sub{ $submission->validate_for_submit; }, qr/No authors in submission info/, 'fails w/o authors');
    $info->{authors} = 'Prince';
    #throws_ok(sub{ $submission->validate_for_submit; }, qr/Expected a last name in "Prince"/, 'fails w/ invalid authors name');
    $info->{authors} = $v;

    # Assembly method required, and correct format
    $v = delete $info->{assembly_method};
    $info->{assembly_method} = 'NO_VDOT';
    throws_ok(sub{ $submission->validate_for_submit; }, qr/Invalid assembly_method/, 'fails w/ invalid assembly_method');
    $info->{assembly_method} = $v;

    # Contact required, format
    $v = delete $info->{contact};
    throws_ok(sub{ $submission->validate_for_submit; }, qr/No contact in submission info/, 'fails w/o contact');
    $info->{contact} = 'Prince';
    #throws_ok(sub{ $submission->validate_for_submit; }, qr/Expected a last name in "Prince"/, 'fails w/ invalid contact name');
    $info->{contact} = $v;

    # Release notes required
    $v = delete $info->{release_notes_file};
    throws_ok(sub{ $submission->validate_for_submit; }, qr/No release_notes_file in submission info/, "validate_for_submit fails w/o release_notes_file");
    $info->{release_notes_file} = 'blah';
    throws_ok(sub{ $submission->validate_for_submit; }, qr/File release_notes_file is defined in submission info, but does not exist/, "validate_for_submit fails w/o release_notes_file");
    $info->{release_notes_file} = $v;

    # Unique ID required
    $v = delete $info->{unique_id};
     throws_ok(sub{ $submission->validate_for_submit; }, qr/No unique_id in submission info/, 'fails w/o unique_id');
    $info->{unique_id} = $v;

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

subtest 'accession_id' => sub{
    plan tests => 2;

    my $submission = $setup{submission};
    ok(!$submission->accession_id, 'submission does not have an accession_id');
    is($submission->accession_id('HNH00000001'), 'HNH00000001', 'submission accession_id');

};

subtest 'tar_basename' => sub{
    plan tests => 1;

    my $submission = $setup{submission};
    like($submission->tar_basename, qr/Crassostrea_virginica_2\.0_\d\d\d\d\-\d\d\-\d\d\.tar/, 'submission tar_basename');

};

subtest 'add_info_for' =>sub{
    plan tests => 5;

    my $submission = $setup{submission};

    my $info = $submission->submission_info;
    $submission->submission_info({});
    throws_ok(sub{ $submission->add_info_for(); }, qr//, 'add_info_for fails w/o submission_info');
    $submission->submission_info($info);

    throws_ok(sub{ $submission->add_info_for(); }, qr//, 'add_info_for fails w/o key');
    throws_ok(sub{ $submission->add_info_for('tbl2asn_params'); }, qr//, 'add_info_for fails w/o value');
    my $params = '-a z -l paired_reads';
    lives_ok(sub{ $submission->add_info_for('tbl2asn_params', $params); }, 'add_info_for');
    is($submission->info_for('tbl2asn_params'), $params, 'info_for tbl2asn_params');

};

done_testing();
