#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Cwd 'cwd';
use Test::More tests => 3;

my %setup;
subtest setup => sub{
    plan tests => 1;

    use_ok('RefImp::Resources::Ncbi::UpdateAccessionNumbersFromReports') or die;
    $setup{file} = File::Spec->join(
        TestEnv::test_data_directory_for_package("RefImp::Resources::Ncbi::ParseAc4htgsReport"),
        "wugsc20160707.HMPB-AAD13A05.phase3.fa2htgs.asn.ac4htgs",
    );

    $setup{project} = RefImp::Project->get(1);

    my $ftp = RefImp::Test::Factory->setup_test_ftp;
    $ftp->mock('ls', sub{ ( $setup{file} ) });
    $ftp->mock('get', sub{ 
            if ( not -l $setup{file} ) {
                symlink($setup{file}, '.');
            }
        }
    );

    $setup{AC444444} = RefImp::Project::GbAccession->create(
        id => 'AC444444',
        version => 1,
        project_id => $setup{project}->id,
        rank => 1,
        center => 'wugsc',
    );

    RefImp::Config::set('ncbi_ftp_host', 'ftp-host');
    RefImp::Config::set('ncbi_ftp_user', 'ftp-user');
    RefImp::Config::set('ncbi_ftp_password', 'ftp-password');

};

subtest 'execute' => sub{
    plan tests => 10;

    $setup{AC999999} = RefImp::Project::GbAccession->get('AC999999');
    ok(!$setup{AC999999}, 'no gb_accession for AC999999');
    my @gb_accessions = RefImp::Project::GbAccession->get(project_id => $setup{project}->id);
    is(@gb_accessions, 1, 'one gb_accession');

    my $cmd = RefImp::Resources::Ncbi::UpdateAccessionNumbersFromReports->execute;
    ok($cmd->result, 'execute');

    @gb_accessions = RefImp::Project::GbAccession->get(project_id => $setup{project}->id);
    is(@gb_accessions, 2, 'added gb_accession');
    $setup{AC999999} = RefImp::Project::GbAccession->get('AC999999');
    ok($setup{AC999999}, 'created AC999999');
    is($setup{AC999999}->center, 'wugsc', 'AC999999 wugsc');
    is($setup{AC999999}->project_id, $setup{project}->id, 'AC999999 project_id');
    is($setup{AC999999}->rank, 1, 'AC999999 rank');
    is($setup{AC999999}->version, 1, 'AC999999 version');

    is($setup{AC444444}->rank, 2, 'AC444444 rank set to 2');

};

subtest 'execute with same accession existing' => sub{
    plan tests => 4;

    $setup{AC999999}->rank(3);

    my $cmd= RefImp::Resources::Ncbi::UpdateAccessionNumbersFromReports->execute;
    ok($cmd->result, 'execute');

    my @gb_accessions = RefImp::Project::GbAccession->get(
        project_id => $setup{project}->id,
    );
    is(@gb_accessions, 2, 'still 2 gb_accessions');
    is($setup{AC999999}->rank, 1, 'AC999999 rank is 1');
    is($setup{AC444444}->rank, 2, 'AC444444 rank is still 2');

};

done_testing();
