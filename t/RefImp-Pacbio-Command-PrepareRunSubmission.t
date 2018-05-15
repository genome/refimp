#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TestEnv;

use Digest::MD5;
use File::Compare;
use File::Temp;
use Path::Class;
use Sub::Install;
use Test::More tests => 2;
use Test::Exception;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    %test = (
        class => 'RefImp::Pacbio::Command::PrepareRunSubmission',
        tempdir => dir( File::Temp::tempdir(CLEANUP => 1) ),
        bioproject => 'BIOPROJECT',
        biosample => 'BIOSAMPLE',
    );

    use_ok($test{class}) or die;

    $test{data_directory} = dir( TestEnv::test_data_directory_for_package('RefImp::Pacbio::Run') );
    ok(-d "$test{data_directory}", "data directory exists");

    Sub::Install::reinstall_sub({
            code => sub{ 'md5sum' },
            into => 'Digest::MD5',
            as => 'hexdigest',
        });

};

subtest 'execute rsii' => sub{
    plan tests => 20;

    my $run_id = '6U00E3';
    my $output_path = $test{tempdir}->subdir('rsii');
    my %params = (
        bioproject => 'BIOPROJECT',
        biosample => 'BIOSAMPLE',
        output_path => "$output_path",
        sample_name => 'H_IJ-HG02818-HG02818_1-lib2',
        library_name => 'HG02818',
        submission_alias => $run_id,
        run_directories => [ $test{data_directory}->subdir($run_id)->stringify ],
    );
    my $cmd = $test{class}->create(%params);
    ok($cmd, 'create command');
    lives_ok(sub{ $cmd->execute; }, 'execute');

    ok(-s $output_path->file($run_id.'.tar'), 'submission tar exists');

    my $output_xml_path = $output_path->subdir($run_id);
    my $expected_xml_path = $test{data_directory}->subdir(join('-', $run_id, 'submission'))->subdir($run_id);
    for my $type (qw/ submission experiment run /) {
        my $xml_basename = join('.', $run_id, $type, 'xml');
        my $f = $output_xml_path->file($xml_basename);
        my $e = $expected_xml_path->file($xml_basename);
        is(File::Compare::compare("$f", "$e"), 0, "$xml_basename XML matches");
    }

    for my $analysis ( @{$cmd->analyses} ) {
        my $links = grep { -l $output_path->file( $_->basename )->stringify } @{$analysis->{analysis_files}};
        ok($links, "links analysis files for ".$analysis->well);
    }

};

subtest 'execute sequel' => sub{
    plan tests => 20;

    my $run_id = '6U00E3';
    my $output_path = $test{tempdir}->subdir('rsii');
    my %params = (
        bioproject => 'BIOPROJECT',
        biosample => 'BIOSAMPLE',
        output_path => "$output_path",
        sample_name => 'H_IJ-HG02818-HG02818_1-lib2',
        library_name => 'HG02818',
        submission_alias => $run_id,
        run_directories => [ $test{data_directory}->subdir($run_id)->stringify ],
    );
    my $cmd = $test{class}->create(%params);
    ok($cmd, 'create command');
    lives_ok(sub{ $cmd->execute; }, 'execute');

    ok(-s $output_path->file($run_id.'.tar'), 'submission tar exists');

    my $output_xml_path = $output_path->subdir($run_id);
    my $expected_xml_path = $test{data_directory}->subdir(join('-', $run_id, 'submission'))->subdir($run_id);
    for my $type (qw/ submission experiment run /) {
        my $xml_basename = join('.', $run_id, $type, 'xml');
        my $f = $output_xml_path->file($xml_basename);
        my $e = $expected_xml_path->file($xml_basename);
        is(File::Compare::compare("$f", "$e"), 0, "$xml_basename XML matches");
    }

    for my $analysis ( @{$cmd->analyses} ) {
        my $links = grep { -l $output_path->file( $_->basename )->stringify } @{$analysis->{analysis_files}};
        ok($links, "links analysis files for ".$analysis->well);
    }

};

done_testing();
