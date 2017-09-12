#!/usr/bin/env refimp-perl

use strict;
use warnings;

use TestEnv;

use Test::Exception;
use Test::More tests => 3;

my %setup;
subtest setup => sub{
    plan tests => 1;

    $setup{pkg} = 'RefImp::Cron::Command::UpdateAccessionsFromReports';
    use_ok($setup{pkg}) or die;

    $setup{project} = RefImp::Project->get(1);

    $setup{file} = File::Spec->join(
        TestEnv::test_data_directory_for_package("RefImp::Resources::Ncbi::SubmissionReport"),
        "wugsc20160707.HMPB-AAD13A05.phase3.fa2htgs.asn.ac4htgs",
    );

    $setup{ftp} = TestEnv::NcbiFtp->setup;
    $setup{ftp}->mock('ls', sub{ ( $setup{file} ) });
    $setup{ftp}->mock('get', sub{
            if ( not -l $setup{file} ) {
                symlink($setup{file}, '.');
            }
        }
    );
    RefImp::Config::set('ncbi_ftp_host', 'ftp-host');
    RefImp::Config::set('ncbi_ftp_user', 'ftp-user');
    RefImp::Config::set('ncbi_ftp_password', 'ftp-password');

};

subtest 'no project submission' => sub{
    plan tests => 1;

    throws_ok(sub{ $setup{pkg}->execute(); }, qr/Failed to update these projects: HMPB-AAD13A05/, 'execute fails w/o project submission');

};

subtest 'execute' => sub{
    plan tests => 3,

    $setup{submission} = RefImp::Project::Submission->create(
        project => $setup{project},
        phase => 3,
        directory => '/tmp',
    );
    ok($setup{submission}, 'create submission');
    ok($setup{pkg}->execute(), 'execute');
    is($setup{submission}->accession_id, 'AC999999', 'set accession on project submission');

};

done_testing();
