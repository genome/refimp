#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Slurp;
use LWP::UserAgent;
use Sub::Install;
use Test::MockObject;
use Test::More tests => 1;

my %setup;
subtest 'setup' => sub{
    plan tests => 2;

    $setup{pkg} = 'RefImp::Assembly::Submission';
    use_ok($setup{pkg}) or die;

    # User Agent
    my $ua = Test::MockObject->new();
    $ua->set_true('timeout');
    $ua->set_true('env_proxy');
    $setup{response} = Test::MockObject->new();

    Sub::Install::reinstall_sub({
        code => sub{ $ua },
        into => 'LWP::UserAgent',
        as => 'new',
        });

    # Load XML, set as decoded content
    my $xml_file = File::Spec->join(TestEnv::test_data_directory_for_package($setup{pkg}), 'esummary.xml');
    my $xml_content = File::Slurp::slurp($xml_file);
    ok($xml_content, 'loaded xml');
    $setup{response}->set_true('is_success');
    $setup{response}->mock('decoded_content', $xml_content);

};

subtest 'create' => sub{
    plan tests => 1;

    $setup{submission} = $setup{pkg}->create(bioproject => 'PRJNA376014');
    ok($setup{submission}, 'create submission');

};

done_testing();
