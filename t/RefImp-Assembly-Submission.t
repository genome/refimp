#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Slurp;
use LWP::UserAgent;
use Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 3;

my %setup;
subtest 'setup' => sub{
    plan tests => 2;

    $setup{pkg} = 'RefImp::Assembly::Submission';
    use_ok($setup{pkg}) or die;

    my $data_dir = TestEnv::test_data_directory_for_package($setup{pkg});
    my $assembly_dir = File::Spec->join($data_dir, 'assembly');
    my %submission_params = (
        agp_file => File::Spec->join($assembly_dir, ''),
        authors => 'Wesley C. Warren,Marta Gomez-Chiarri,Chad Tomlinson',
        bioproject => 'PRJNA376014',
        biosample => 'SAMN06349363',
        contigs_file => File::Spec->join($assembly_dir, ''),
        coverage => '20X',
        release_date => 'immediately after processing',
        supercontigs_file => File::Spec->join($assembly_dir, ''),
        version => '',
    );
    $setup{submission_params} = \%submission_params;

    # User Agent
    $setup{ua} = Test::MockObject->new();
    $setup{ua}->set_true('timeout');
    $setup{ua}->set_true('env_proxy');

    Sub::Install::reinstall_sub({
        code => sub{ $setup{ua} },
        into => 'LWP::UserAgent',
        as => 'new',
        });

    # Load XML, set as decoded content
    my $xml_file = File::Spec->join($data_dir, join('.', 'esummary', $submission_params{biosample}, 'xml'));
    my $xml_content = File::Slurp::slurp($xml_file);
    ok($xml_content, 'loaded xml');

    $setup{response} = Test::MockObject->new();
    $setup{response}->set_true('is_success');
    $setup{response}->set_always('decoded_content', $xml_content);
    $setup{ua}->set_always('get', $setup{response});

};

subtest 'create fails' => sub{
    plan tests => 9;

    my $submission_params = $setup{submission_params};
    for my $k ( keys %$submission_params ) {
        my $v = delete $submission_params->{$k};
        throws_ok(sub{ $setup{pkg}->create(%$submission_params); }, qr//, "create fails w/o $k");
        $submission_params->{$k} = $v;
    }

};

subtest 'create' => sub{
    plan tests => 2;

    my $submission = $setup{pkg}->create(%{$setup{submission_params}});
    ok($submission, 'create submission');
    ok($submission->esummary, 'created and set biosample esummary',);

    $setup{submission} = $submission;

};

done_testing();
