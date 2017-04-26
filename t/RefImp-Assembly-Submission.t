#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Slurp;
use LWP::UserAgent;
use Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 2;

my %setup;
subtest 'setup' => sub{
    plan tests => 2;

    $setup{pkg} = 'RefImp::Assembly::Submission';
    use_ok($setup{pkg}) or die;
    my %submission_params = (
        bioproject => 'PRJNA376014',
        biosample => 'SAMN06349363',
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
    my $xml_file = File::Spec->join(TestEnv::test_data_directory_for_package($setup{pkg}), join('.', 'esummary', $submission_params{biosample}, 'xml'));
    my $xml_content = File::Slurp::slurp($xml_file);
    ok($xml_content, 'loaded xml');

    $setup{response} = Test::MockObject->new();
    $setup{response}->set_true('is_success');
    $setup{response}->set_always('decoded_content', $xml_content);
    $setup{ua}->set_always('get', $setup{response});

};

subtest 'create' => sub{
    plan tests => 2;

    my $submission = $setup{pkg}->create(%{$setup{submission_params}});
    ok($submission, 'create submission');
    ok($submission->esummary, 'created and set biosample esummary',);

    $setup{submission} = $submission;

};

done_testing();
