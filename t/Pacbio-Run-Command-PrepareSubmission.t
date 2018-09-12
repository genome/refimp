#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use TenxTestEnv;

use Digest::MD5;
use File::Compare;
use File::Temp;
use Path::Class;
use Sub::Install;
use Test::Exception;
use Test::More tests => 4;

my %test;
subtest 'setup' => sub{
    plan tests => 2;

    %test = (
        class => 'Pacbio::Run::Command::PrepareSubmission',
        tempdir => dir( File::Temp::tempdir(CLEANUP => 1) ),
        bioproject => 'BIOPROJECT',
        biosample => 'BIOSAMPLE',
    );

    use_ok($test{class}) or die;

    $test{data_directory} = dir( TenxTestEnv::test_data_directory_for_class('Pacbio::Run') );
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
    my $machine_type = 'rsii';
    my $output_path = $test{tempdir}->subdir($machine_type);
    my %params = (
        bioproject => 'BIOPROJECT',
        biosample => 'BIOSAMPLE',
        machine_type => $machine_type,
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
        my @expected = map { my $bn = $_->basename; $bn =~ s/^\.//; $output_path->file($bn)->stringify; } ($analysis->metadata_xml_file, @{$analysis->{analysis_files}});
        my @linked = grep { -l "$_" } @expected;
        is_deeply(\@linked, \@expected, "linked analysis files for ".$analysis->well);
    }

};

subtest 'execute sequel' => sub{
    plan tests => 11;

    my $run_id = '6U00I7';
    my $machine_type = 'sequel';
    my $output_path = $test{tempdir}->subdir($machine_type);
    my %params = (
        bioproject => 'BIOPROJECT',
        biosample => 'BIOSAMPLE',
        machine_type => 'sequel',
        output_path => "$output_path",
        sample_name => 'HG03486_Mende_4808Ll',
        library_name => 'HG03486',
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
        my @expected = map { my $bn = $_->basename; $bn =~ s/^\.//; $output_path->file($bn)->stringify; } ($analysis->metadata_xml_file, @{$analysis->{analysis_files}});
        my @linked = grep { -l "$_" } @expected;
        is_deeply(\@linked, \@expected, "linked analysis files for ".$analysis->well);
    }

};

subtest 'type_for_file' => sub{
    plan tests => 5;

    my $cmd = $test{class}->create(machine_type => 'rsii');
    throws_ok(sub{ $cmd->type_for_file; }, qr/No file given/, 'fails w/o file');
    is($cmd->type_for_file( $test{tempdir}->file('foo.bar.bam') ), 'bam', 'type for bam');
    is($cmd->type_for_file( $test{tempdir}->file('foo.h5') ), 'PacBio_HDF5', 'type for hd5');
    is($cmd->type_for_file( $test{tempdir}->file('foo.bar.bam.xml') ), 'xml', 'type for rsii bam');
    $cmd->machine_type('sequel');
    is($cmd->type_for_file( $test{tempdir}->file('foo.bar.bam.xml') ), 'bam', 'type for sequel xml');

};

done_testing();
