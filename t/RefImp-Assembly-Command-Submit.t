#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use Date::Format;
use MIME::Lite;
use Sub::Install;
use Test::Exception;
use Test::MockObject;
use Test::More tests => 3;

my %setup;
subtest 'setup' => sub{
    plan tests => 1;

    $setup{pkg} = 'RefImp::Assembly::Command::Submit';
    use_ok($setup{pkg}) or die;

    my $data_dir = TestEnv::test_data_directory_for_package('RefImp::Assembly::Submission');
    my $assembly_dir = File::Spec->join($data_dir, 'assembly');
    $setup{submission_yml} = File::Spec->join($data_dir, 'submission.yml');

    Sub::Install::reinstall_sub({
        code => sub{ 1 },
        as => 'validate_for_submit',
        into => 'RefImp::Assembly::Submission',    
        });

    $setup{ftp} = TestEnv::NcbiFtp->setup;

    my $msg = Test::MockObject->new;
    Sub::Install::reinstall_sub({
        code => sub{
            my ($class, %p) = @_;
            is_deeply($p{To}, ['genomes@ncbi.nlm.nih.gov'], 'email To');
            is_deeply($p{Cc}, ['mgi-submission@gowustl.onmicrosoft.com'], 'email Cc');
            is($p{From}, 'mgi-submission@gowustl.onmicrosoft.com', 'email From');
            like($p{Subject}, qr/Assembly Submission/, 'email Subject');
            ok($p{Type}, 'Type defined');
            $msg;
        },
        as => 'new',
        into => 'MIME::Lite',    
        });

    $msg->mock('attach', sub{
            my ($class, %p) = @_;
            like($p{Data}, qr/The McDonnell Genome Institute has submitted a new assembly\nfrom the BioSample SAMN06349363 of BioProject PRJNA376014 to GenBank/, 'email msg attached');
            ok($p{Type}, 'Data defined');
        }
    );
    $msg->mock('send', sub{ 1 });

};

subtest 'execute fails' => sub{
    plan tests => 1;

    throws_ok(sub{ $setup{pkg}->execute(submission_yml => '/blah'); }, qr/Submission YAML does not exist/, 'execute fails w/ non existing submission yml');

};

subtest 'execute' => sub{
    plan tests => 14;

    my $cmd = $setup{pkg}->create(submission_yml => $setup{submission_yml});

    $setup{ftp}->mock('cwd', sub{ is($_[1], 'TEMP', 'correct cwd'); });
    $setup{ftp}->mock('put', sub{ is($_[1], $cmd->tar_file); });
    $setup{ftp}->mock('size', sub{ -s $cmd->tar_file; });

    ok($cmd->execute, 'execute submit');
    ok($cmd->result, 'cmd result');

    ok($cmd->submission, 'created submission');
    my $tar_file_basename = join('.', 'Crassostrea_virginica_2.0', Date::Format::time2str('%Y-%m-%d', time()), 'tar');
    like($cmd->tar_file, qr/$tar_file_basename$/, 'tar_file name');

    ok(-s $cmd->tar_file, 'created tar file');
    print "HERE\n"; <STDIN>;

};

done_testing();
