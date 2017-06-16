#!/usr/bin/env perl5.10.1

use strict;
use warnings;

use TestEnv;

use File::Temp;
use File::Copy;
use Path::Class;
use Sub::Install;
use Test::Exception;
use Test::More tests => 4;

my %test;
subtest 'setup' => sub{
    plan tests => 3;

    $test{pkg} = 'RefImp::Tenx::Command::Reference::Mkref';
    use_ok($test{pkg}) or die;

    $test{taxon} = RefImp::Taxon->get(1);
    $test{data_dir} = dir( TestEnv::test_data_directory_for_package($test{pkg}) );
    my $orig_fasta_file = $test{data_dir}->file('test.fasta');
    $test{output_directory} = dir( File::Temp::tempdir(CLEANUP => 1) );
    $test{fasta_file} = $test{output_directory}->file('test.fasta');
    File::Copy::copy($orig_fasta_file->stringify, $test{fasta_file}->stringify);
    ok(-s $test{fasta_file}->stringify, 'copied fasta file');

    $test{cmd} = $test{pkg}->create(
        name => 'TESTREF',
        fasta_file => $test{fasta_file}->stringify,
        taxon => $test{taxon},
    );
    ok($test{cmd}, 'create command');

};

subtest 'properties and tenx command' => sub{
    plan tests => 3;

    my @tenx_cmd = $test{cmd}->_tenx_command;
    my @expected_tenx_cmd = ( 'longranger', 'mkref', $test{fasta_file}->stringify );
    is_deeply(\@tenx_cmd, \@expected_tenx_cmd, '_tenx_cmd');

    is($test{cmd}->_fasta_file->stringify, $test{fasta_file}->stringify, '_fasta_file');
    is($test{cmd}->output_directory->stringify, $test{output_directory}->stringify, 'output_directory');

};

subtest 'execute fails' => sub{
    plan tests => 2;

    my $pkg = $test{pkg};
    throws_ok(
        sub{ $pkg->execute(
                name => 'TESTREF',
                fasta_file => '/blah',
                taxon => $test{taxon},
            ); },
        qr/Fasta file \/blah does not exist/,
        'fails with invalid directory',
    );

    my $existing_ref = RefImp::Tenx::Reference->__define__(name => 'daRef', directory => '/tmp');
    throws_ok(
        sub{ $pkg->execute(
                name => 'daRef',
                fasta_file => '/blah',
                taxon => $test{taxon},
            ); },
        qr/Reference for daRef already exists/,
        'fails with existing reference',
    );

};

subtest 'execute' => sub{
    plan tests => 3;

    # Don't run bsub/longranger command
    my $_bsub_command = $test{pkg}->can('_bsub_command');
    Sub::Install::reinstall_sub({
            code => sub{ (qw/ echo Reference successfully created /) },
            as => '_bsub_command',
            into => $test{pkg},
        });
    my $_tenx_command = $test{pkg}->can('_tenx_command');
    Sub::Install::reinstall_sub({
            code => sub{ () },
            as => '_tenx_command',
            into => $test{pkg},
        });

    # Make the output directory
    my $expected_reference_directory = $test{output_directory}->subdir('refdata-test');
    mkdir $expected_reference_directory->stringify;

    ok($test{cmd}->execute, 'execute');
    my $reference = RefImp::Tenx::Reference->get(name => 'TESTREF');
    ok($reference, 'created reference object');
    is($reference->directory, $expected_reference_directory->stringify);

};

done_testing();
